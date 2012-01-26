require 'seymour/dsl'

module Seymour
  module ActivityDocument

    # The Element class is a simple Hash modification
    # that allows for cached field access via method call
    # instead of hash access.  It also automatically proxies
    # non-cached method calls through to the appropriate
    # underlying model that it represents.
    #
    # @example Access a cached 'full_name' field
    #   element['full_name']
    #   element.full_name
    #   element.followers # Loads model and calls followers on it if it responds_to? :followers
    class Element < Hash
      include Mongoid::Fields::Serializable

      class ElementHash < Hash
        def method_missing(meth, *args, &block)
          if key?(meth.to_s)
            return self[meth.to_s]
          else
            @model ||= self['_type'].to_s.camelcase.constantize.find(self['_id'])
            if @model && @model.respond_to?(meth)
              return @model.send(meth, *args, &block)
            else
              super
            end
          end
        end
      end

      def deserialize(object)
        if object.kind_of? Hash
          object = ElementHash.new.replace(object)
        end
        object
      end
    end

    extend ActiveSupport::Concern

    included do
      attr_accessor :activity_keys

      include Mongoid::Document
      include Mongoid::Timestamps

      store_in Seymour::Config.activity_collection
    
      # Basic Activity fields.  These will be overridden by the DSL calls if used to provide
      # appropriate aliases.
      field :actor,       type: Element
      field :object,      type: Element
      field :activity_target,      type: Element

      attr_reader :actor_cache, :object_cache, :activity_target_cache
          
      index [['actor._id', Mongo::ASCENDING], ['actor._type', Mongo::ASCENDING]]
      index [['object._id', Mongo::ASCENDING], ['object._type', Mongo::ASCENDING]]
      index [['activity_target._id', Mongo::ASCENDING], ['activity_target._type', Mongo::ASCENDING]]
          
      validates_presence_of :actor
      # Only assign the data once automatically.  If you want to update it later you MUSt
      # call .refresh_data manually.
      before_save :assign_data_if_needed
      
      extend Seymour::DSL
      Seymour::Config.base_activity_class = self.name
      register_activity
    end
    
    module ClassMethods
      # Publishes an activity
      #
      # @param [ Hash ] data The data to initialize the activity with as well as the channel options.
      #
      # @return [Seymour::ActivityDocument] An Activity instance with data
      def publish!(options = {})
        @activity_keys ||= begin
          activity_keys = [:actor, :object, :activity_target]
          [:actor, :object, :activity_target].each do |type|
            activity_keys << send("defined_#{type}".to_sym).try(:[],:alias)
          end
          activity_keys.compact!
          activity_keys
        end
        activity = create!(options.slice(*@activity_keys))
        activity.distribute!(options.except(*@activity_keys))
        activity
      end
      
      def activities_by(actor, options={})
        query = {'actor._id' => actor.id, 'actor._type' => actor.class.to_s}
        query.merge!({:_type => options[:type]}) if options[:type]
        self.where(query).desc(:created_at)
      end

      # Returns this Activity class' default channel options merged with and overridden
      # by the provided options hash.
      #
      # @param [ Hash ] options Any additional/overridden channel options provided to publish!
      #
      # @return [ Hash ] The merged channel options hash to be used for delivering this Activity.
      def channel_options(options = {})
        default_channel_options.deep_merge(options)
      end

      protected
      
      # TODO: Revisit how this is handled...
      #
      # Registers the activity with the ActivityRegistry.  Wanted this to be done by the
      # included block but that doesn't play nice with inheritance since the module is
      # only included in the base class and the subclasses may not be loaded yet.
      # One alternative would be to call this the first time Seymour.publish is called
      # and find/register all Activity classes.
      def register_activity
        Seymour::ActivityRegistry.register(self)
      end
    end
    
    # Returns an instance of an actor, object or target
    #
    # @param [ Symbol ] type The data type (actor, object, target) to return an instance for.  Type alias may also be used.
    #
    # @return [Mongoid::Document] document A mongoid document instance
    def load_instance(type)
      cache_key = "@#{type}_cache".to_sym
      data = self.send(type)
      
      if (instance = self.instance_variable_get(cache_key)) || !data.is_a?(Hash)
        return instance || data
      else
        instance = nil
        if data['root_type'] && data['root_id'] && data['embed_path']
          # Trying to resurrect an embedded document.
          parent = data['root_type'].to_s.camelcase.constantize.find(data['root_id'])
          if parent
            instance = parent
            embed_paths = data['embed_path'].split('::')
            embed_paths.each do |path|
              parts = path.split(':')
              if parts.length == 2
                instance = instance.send(parts[0]).find(parts[1])
              else
                instance = instance.send(parts[0])
              end
            end
          end
        else
          instance = data['_type'].to_s.camelcase.constantize.find(data['_id'])
        end
        # Cache the instance for future access...
        self.instance_variable_set(cache_key, instance)
        #self.send("#{type}=".to_sym, instance)
        instance
      end
    end

    def refresh_data
      assign_data
      save(:validate => false)
    end

    # Redistributes this Activity to its configured Channels via Seymour's current
    # Distribution mechanism.
    #
    # @example Redistribution
    #   activity.redistribute
    #
    # @param [ Hash ] options Configuration options for the Activity's Channels
    def redistribute!(options = {})
      Seymour::Distribution.distribute(self, channel_options(options))
    end
    alias_method :distribute!, :redistribute!
  
    protected

    def channel_options(options = {})
      self.class.channel_options(options)
    end

    def assign_data_if_needed
      assign_data if self.changed?
    end
      
    def assign_data
      [:actor, :object, :activity_target].each do |type|
        next unless object = load_instance(type)
        unless type_def = self.class.send("defined_#{type}".to_sym)
          # If we hit an unconfigured Activity element, nuke it so we don't try saving
          # a full Mongoid object.  Alternatively we could just set _id and _type or
          # throw an error.
          write_attribute(type, nil)
          next
        end

        class_sym = object.class.name.underscore.to_sym

        # If we have a class restriction on this Activity element, respect it
        if type_def[:class] && class_sym != type_def[:class].name.underscore.to_sym
          raise Seymour::InvalidData.new(class_sym)
        end
    
        hash = Element.new
        hash['_id'] = object.id
        hash['_type'] = object.class.name

        # Handle embedded documents...
        if object.embedded?
          # Construct the embed path
          embeds = []
          parent = object
          embeds << (parent.metadata.macro == :embeds_many ? "#{parent.metadata.name}:#{parent.id}" : "#{parent.metadata.name}")
          while (parent = parent._parent).embedded?
            embeds << (parent.metadata.macro == :embeds_many ? "#{parent.metadata.name}:#{parent.id}" : "#{parent.metadata.name}")
          end
          hash['root_id'] = parent.id
          hash['root_type'] = parent.class.name
          hash['embed_path'] = embeds.reverse.join('::')
        end
        
        type_def[:cache].each do |field|
          if field.is_a?(Symbol)
            raise Seymour::InvalidField.new(field) unless object.respond_to?(field)
            hash[field.to_s] = object.send(field)
          elsif field.is_a?(Hash)
            key = field.first[0]
            callable = field.first[1]
            hash[key.to_s] = callable.call(object)
          else
            raise Seymour::InvalidField.new(field)
          end
        end

        write_attribute(type, hash)      
      end
    end      
  end
end
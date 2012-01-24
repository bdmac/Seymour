module Seymour
  module Distributors
    class Resque
      def self.queue
        Seymour::Config.resque_queue
      end

      def self.perform(activity_id, channel_options)
        activity = Seymour::Config.base_activity_class.camelcase.constantize.find(activity_id)
        Seymour::Channels.channels(deserialize(channel_options, activity)).each do |channel|
          channel.deliver(activity)
        end
      end

      def self.distribute(activity, channel_options = {})
        ::Resque.enqueue(self.class, activity.id.to_s, serialize(channel_options, activity))
      end

    protected
      
      def self.serialize(channel_options, activity)
        channel_options.each do |channel_name, options|
          next if options[:recipients].is_a?(Symbol)
          recipients = options[:recipients]
          if recipients.respond_to?(:call)
            recipients = recipients.call(activity)
          end
          recipients = recipients.map do |recipient|
            if !recipient.class.include?(Mongoid::Document)
              recipient
            else
              {:_id => recipient.id.to_s, :klass => recipient.class.name}
            end
          end
          options[:recipients] = recipients
        end
        channel_options
      end
      
      def self.deserialize(channel_options, activity)
        channel_options.symbolize_keys!
        channel_options.each do |channel_name, options|
          options.symbolize_keys!
          if options[:recipients].respond_to?(:to_sym)
            options[:recipients] = options[:recipients].to_sym
            next
          end
          recipients = options[:recipients]
          recipients = recipients.map do |recipient|
            if recipient.class.include?(Mongoid::Document)
              recipient
            else
              recipient['klass'].constantize.find(recipient['_id'])
            end
          end
          options[:recipients] = recipients
        end
        channel_options
      end
    end
  end
end
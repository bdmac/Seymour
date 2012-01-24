module Seymour
  module ActivityRegistry

    extend self

    def registry
      @registry ||= {}
    end

    # Registers the provided klass as an available Activity class with a
    # verb based on its class name.  Will also remove any namespace modules
    # from the class to simplify verb names.
    #
    # This method also registers any subclasses of the provided class to allow
    # Activity inheritance to function properly.
    #
    # @example Register the activity class.
    #   ActivityMapper.register(SuperFun)
    #
    # @param [ Class ] klass The class to register as an Activity.  Must include Seymour::Activity.
    #
    # @return [ Symbol ] The symbolized verb that serves as the registry key.
    def register(klass)
      unless klass.include?(Seymour::ActivityDocument)
        raise Seymour::InvalidActivity, "#{klass.name} must include Seymour::Activity to be added to the ActivityRegistry."
      end
      verb = verb_for(klass)
      registry[verb] = klass
      klass.descendants.each do |descendant|
        registry[verb_for(descendant)] = descendant
      end
      verb
    end

    # Looks up an activity by the provided verb.
    #
    # @example Find the activity class.
    #   ActivityMapper.find(:super_fun)
    #
    # @param [ Symbol ] verb The verb representing the Activity
    #
    # @return [ Class ] The Activity class for the provided verb.
    def find(verb)
      if klass = registry[verb]
        return klass
      else
        # Attempt to auto-register an Activity class
        begin
          return register(verb.to_s.camelcase.constantize)
        rescue NameError
          raise Seymour::InvalidActivity, "Unable to locate a registered Activity for #{verb}"
        end
      end
    end
  
    # Symbolizes an Activity class to use as a key in the registry.  Removes any namespace
    # modules from the class as well.
    #
    # @example Get an activity verb for a provided class.
    #   ActivityMapper.verb_for(SuperFun) => :super_fun
    #   ActivityMapper.verb_for(Activities::SuperFun) => :super_fun
    #
    # @param [ Class ] klass The class to symbolize into a verb.
    #
    # @return [ Symbol ] The symbolized version of the class name.
    def verb_for(klass)
      klass.name.demodulize.underscore.to_sym
    end
  end
end
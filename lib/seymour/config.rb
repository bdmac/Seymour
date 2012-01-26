module Seymour
  module Config
    extend self

    attr_accessor :settings
    @settings = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    #   Config.option(:distribution, :default => :immediate)
    #
    # @param [ Symbol ] name The name of the configuration option.
    # @param [ Hash ] options Extras for the option.
    #
    # @option options [ Object ] :default The default value.
    #
    def option(name, options = {})
      settings[name] = options[:default]

      class_eval <<-RUBY
        def #{name}
          settings[#{name.inspect}]
        end

        def #{name}=(value)
          settings[#{name.inspect}] = value
        end

        def #{name}?
          #{name}
        end
      RUBY
    end

    option :activity_directory, default: 'app/models/activities'
    option :activity_collection, default: :activities
    option :feed_collection, default: :feeds
    option :feed_batch_size, default: 1000
    option :distribution, default: :resque
    option :resque_queue, default: :activities
    option :channels, default: [:feed]
    option :base_activity_class, default: nil
    option :base_feed_class, default: nil
  end
end
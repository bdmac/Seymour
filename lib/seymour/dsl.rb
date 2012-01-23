module Seymour
  module DSL
    extend self

    attr_reader :default_channel_options
    
    def self.dsl_methods(*args)
      args.each do |method|
        class_eval <<-RUBY
          attr_reader :defined_#{method}
          def define_#{method}(name, options = {})
            @defined_#{method} = { alias: name, cache: options[:cache] || [], class: options[:class] }
            if options[:required]
              validates :#{method}, presence: true
            end
            field :#{method}, type: Seymour::ActivityDocument::Element, as: name.to_sym
          end
        RUBY
      end
    end

    dsl_methods :actor, :object, :target

    # Configures the default channel options to deliver Activity to.
    #
    # @example Deliver to all users' feeds
    #   DSL.deliver_to(:feed, recipients: -> { User.all })
    #
    # @param [ Symbol ] channel Symbolized name of a Seymour::Channel.
    # @param [ Hash ] options The default options for the Channel.
    def deliver_to(channel, options = {})
      @default_channel_options ||= {}
      @default_channel_options[channel] = options
    end
  end
end
module Seymour
  module Channels
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def deliver(activity)
        fail # Implement in subclasses
      end

    protected
      
      def recipients(activity)
        recipients = options[:recipients]

        if recipients.respond_to?(:call)
          recipients = recipients.call(activity)
        elsif recipients.is_a?(Symbol)
          recipients = activity.send(recipients)
        end
        raise ::Seymour::InvalidRecipients.new(recipients.class) if recipients && !recipients.respond_to?(:each)
        recipients
      end
    end
  end
end
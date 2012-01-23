module Seymour
  module Channels
    class Feed < Base
      def deliver(activity)
        recipients = recipients(activity)
        return unless recipients
        recipients.each do |recipient|
          recipient.add_activity_to_feed!(activity)
        end
      end
    end
  end
end
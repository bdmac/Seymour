module Seymour
  module Channels
    class Feed < Base
      def deliver(activity)
        actor_id = activity.load_instance(:actor).id.to_s
        recipients = recipients(activity)
        return unless recipients
        recipients.each do |recipient|
          recipient.add_activity_to_feed!(activity) unless recipient.id.to_s == actor_id
        end
      end
    end
  end
end
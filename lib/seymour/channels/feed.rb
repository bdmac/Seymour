module Seymour
  module Channels
    class Feed < Base      
      def deliver(activity)
        actor_id = activity.load_instance(:actor).id.to_s
        recipients = recipients(activity)
        return unless recipients
        
        begin
          Mongoid.unit_of_work(disable: :all) do
            if recipients.kind_of?(Mongoid::Criteria)
              # We can only work with Criteria in batches
              batch_size = ::Seymour::Config.feed_batch_size
              0.step(recipients.count, batch_size) do |offset|
                recipients.limit(batch_size).skip(offset).each do |recipient|
                  recipient.add_activity_to_feed!(activity) unless recipient.id.to_s == actor_id
                end
              end
            else
              # Anything else we get for recipients must respond to each
              recipients.each do |recipient|
                recipient.add_activity_to_feed!(activity) unless recipient.id.to_s == actor_id
              end
            end
          end
        rescue ArgumentError
          # We're using a non-patched version of Mongoid without a way to disable identity map.
          if recipients.kind_of?(Mongoid::Criteria)
            # We can only work with Criteria in batches
            batch_size = ::Seymour::Config.feed_batch_size
            0.step(recipients.count, batch_size) do |offset|
              recipients.limit(batch_size).skip(offset).each do |recipient|
                recipient.add_activity_to_feed!(activity) unless recipient.id.to_s == actor_id
              end
            end
          else
            # Anything else we get for recipients must respond to each
            recipients.each do |recipient|
              recipient.add_activity_to_feed!(activity) unless recipient.id.to_s == actor_id
            end
          end
        end
      end
    end
  end
end
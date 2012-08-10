module Seymour
  module Distributors
    class Sidekiq
      include ::Sidekiq::Worker
      sidekiq_options :queue => Seymour::Config.background_queue

      def perform(activity_id, channel_options)
        activity = Seymour::Config.base_activity_class.camelcase.constantize.find(activity_id)
        Seymour::Channels.channels(deserialize(channel_options, activity)).each do |channel|
          channel.deliver(activity)
        end
      end

      def self.distribute(activity, channel_options = {})
        channel_options.each do |channel_name, options|
          temp = {channel_name => options}
          self.perform_async(activity.id.to_s, serialize(temp, activity))
        end
      end
    end
  end
end
require "seymour/distributions/base"

module Seymour
  module Distribution
    class Resque < Base
      def self.perform(activity_id, channel_options)
        activity = Seymour::Config.base_activity_class.camelcase.constantize.find(activity_id)
        Seymour::Channels.channels(channel_options).each do |channel|
          channel.deliver(activity)
        end
      end

      def self.distribute(activity, channel_options = {})
        Resque.enque(Seymour::Distributions::Resque, activity.id.to_s, channel_options)
      end
    end
  end
end
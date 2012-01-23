require "seymour/distributions/base"

module Seymour
  module Distribution
    class Immediate < Base
      def self.distribute(activity, channel_options = {})
        Seymour::Channels.channels(channel_options).each do |channel|
          channel.deliver(activity)
        end
      end
    end
  end
end
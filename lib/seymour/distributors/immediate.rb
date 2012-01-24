module Seymour
  module Distributors
    class Immediate
      def self.distribute(activity, channel_options = {})
        Seymour::Channels.channels(channel_options).each do |channel|
          channel.deliver(activity)
        end
      end
    end
  end
end
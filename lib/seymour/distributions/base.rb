module Seymour
  module Distribution
    class Base
      def self.distribute(activity, channel_options = {})
        fail # Implement in subclasses
      end
    end
  end
end
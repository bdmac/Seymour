module Seymour
  module Distribution
    extend self

    attr_writer :distributor

    # Returns the configured Distributor class to use for Activity distribution.  Allows
    # directly specifying the distributor as well.
    #
    # @return [ Seymour::Distributor ] The currently configured Distributor class.
    #
    # @raise [ Seymour::InvalidDistribution ] If the configured Distributor class is not valid.
    def distributor
      begin
        @distributor || Seymour::Distributors.const_get(Seymour::Config.distribution.to_s.split("_").map {|p| p.capitalize}.join(""))
      rescue NameError
        raise Seymour::InvalidDistribution.new(Seymour::Config.distribution)
      end
    end

    # Distributes a given Activity using the configured Distributor to the Channels specified
    # by channel_options.
    #
    # @example Distribute an activity.
    #   Seymour::Distribution.distribute(activity, {feed: {recipients: [Actor]}})
    #
    # @param [ Seymour::ActivityDocument ] activity The activity document to be distributed.
    # @param [ Hash ] channel_options The channels to be distributed to.
    def distribute(activity, channel_options)
      distributor.distribute(activity, channel_options)
    end
  end
end
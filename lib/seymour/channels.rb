module Seymour
  module Channels
    # Gets the appropriate channels based on a hash of channel options.
    #
    # @example Fetch the channels.
    #   Seymour::Channels.channels({feed: {recipients: [ Actor ]}})
    #
    # @param [ Hash ] options The channel options needed to construct any desired channels.
    #
    # @return [ Array[Seymour::Channel] ] The configured channel objects specified by the options.
    def self.channels(options)
      channels = []
      return channels unless options
      options.each do |channel_name, channel_opts|
        begin
          channel = Seymour::Channels.const_get(channel_name.to_s.split("_").map {|p| p.capitalize}.join(""))
          channels << channel.new(channel_opts)
        rescue NameError
          # don't stop on a missing channel.
        end
      end
      channels
    end
  end
end
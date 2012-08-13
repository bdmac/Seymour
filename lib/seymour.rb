require "mongoid"
require "seymour/version"
require "seymour/config"
require "seymour/errors"
require "seymour/actor"
require "seymour/activity_registry"
require "seymour/feed_document"
require "seymour/activity_document"
require "seymour/distribution"
require "seymour/channels"
require "seymour/channels/base"
require "seymour/channels/feed"
require "seymour/distributors/immediate"
require "seymour/distributors/background"
require "seymour/distributors/resque"
require "seymour/distributors/sidekiq" if defined?(::Sidekiq)
require "seymour/railtie" if defined?(Rails)

module Seymour
  extend self
  
  def configure
    block_given? ? yield(Config) : Config
  end
  alias :config :configure

  # Publishes an activity using an activity name and data.  Acts as a factory method
  # looking up the appropriate activity class using the ActivityRegistry.
  #
  # @param [ Symbol ] verb The verb form of the activity
  # @param [ Hash ] options The data to initialize the activity with along with channel options if desired.
  #
  # @return [ Seymour::ActivityDocument ] An Activity instance with data
  def publish(verb, options)
    Seymour::ActivityRegistry.find(verb).publish!(options)
  end
end
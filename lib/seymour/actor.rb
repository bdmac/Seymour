module Seymour
  module Actor
    extend ActiveSupport::Concern

    included do
      has_one :feed, as: :owner, class_name: Seymour::Config.base_feed_class, dependent: :delete
      after_destroy :delete_activities
    end

    # Publishes an Activity type with the given options using this actor
    # as the Activity's actor.
    #
    # @example Publish an activity
    #   actor.publish_activity(:new_comment, comment: comment)
    #
    # @param [ Symbol ] name The symbolized name of the Activity type.
    # @param [ Hash ] options The options for publishing the Activity.
    #
    # @return [ Seymour::ActivityDocument ] An Activity instance with data that is being published by a configured Distributor.
    def publish_activity(name, options={})
      Seymour.publish(name, {:actor => self}.merge(options))
    end

    # Convenience method for Feed channel to add incoming activity to the Actor's feed.
    #
    # @example Add Activity to the Actor's feed
    #   actor.add_activity_to_feed!(activity)
    #
    # @param [ Seymour::ActivityDocument ] An Activity instance to add to this Actor's feed.
    def add_activity_to_feed!(activity)
      self.create_feed unless self.feed
      self.feed.add_to_set(:feed_item_ids, activity.id)
    end

    # Fetch the incoming activities for this Actor.
    #
    # @param [ Hash ] options Options for retrieving the Actor's activity stream.
    def incoming_activity_stream(options = {})
      self.create_feed unless self.feed
      feed.feed_items(options)
    end
  
    # Fetch the outgoing activities for this Actor.
    #
    # @param [ Hash ] options Options for retrieving the Actor's activity stream.
    def outgoing_activity_stream(options = {})
      Seymour::Config.base_activity_class.camelcase.constantize.activities_by(self, options)
    end
    
    protected
    
    # Destroy any activities by this actor.  Override with more performant version if desired.
    def delete_activities
      outgoing_activity_stream.destroy_all
    end
  end
end
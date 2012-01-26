module Seymour
  module FeedDocument
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in Seymour::Config.feed_collection
    
      belongs_to :owner, polymorphic: true
      has_and_belongs_to_many :feed_items, class_name: Seymour::Config.base_activity_class, order: :_id.desc, inverse_of: nil

      index [['owner_id', Mongo::ASCENDING], ['owner_type', Mongo::ASCENDING]]
          
      validates :owner, presence: true
      validates_uniqueness_of :owner_id

      Seymour::Config.base_feed_class = self.name
    end    
  end
end
class Post
  include Mongoid::Document
  include Seymour::Actor
  
  field :title, type: String
  field :body, type: String
  field :slug, type: String
  
  belongs_to :user
  embeds_many :comments
end
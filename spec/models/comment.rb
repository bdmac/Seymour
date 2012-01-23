class Comment
  include Mongoid::Document

  field :content, type: String

  belongs_to :user
  embedded_in :post
  embeds_many :likes
end
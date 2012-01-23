class Like
  include Mongoid::Document

  belongs_to :user
  embedded_in :comment
end
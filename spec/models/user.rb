class User
  include Mongoid::Document
  include Seymour::Actor
  
  field :full_name
  field :name
  field :slug

  def followers
    User.all
  end
end
class Activities::NewPost < Activities::Activity
  register_activity
  define_actor  :author, cache: [:full_name, :slug]
  define_object :post, cache: [:title, :slug]
  
  deliver_to :feed, recipients: -> activity {User.all}
end
class Activities::NewComment < Activities::Activity
  register_activity
  define_actor  :comment_author, cache: [:full_name, :slug]
  define_object :comment, cache: [:content]
  define_activity_target :post, cache: [:title, :slug]
  
  deliver_to :feed, recipients: -> activity {activity.comment_author.followers}
end
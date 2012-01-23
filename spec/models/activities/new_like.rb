class Activities::NewLike < Activities::Activity
  register_activity
  define_actor  :liker, cache: [:full_name, :slug]
  define_object :like
  define_target :comment, cache: [:content]
  
  deliver_to :feed, recipients: -> activity {activity.liker.followers}
end
# Seymour

Feed me Seymour!  Feed Seymour activities and it will ensure they are distributed as needed.  Seymour allows you to configure
multiple distribution channels for your activities such as feeds and email.  Additional distribution channels can be added
and configured as needed for your application (such as text messaging or iPhone push notifications).

For activity storage and feed distribution only mongodb and the Mongoid ODM is currently supported.

Seymour uses a fan out on write approach to activity distribution.  It does not provide any mechanisms for refining the feed, it simply
distributes activities to appropriate parties via defined channels.

Seymour supports several distribution mechanisms.  Activities _can_ be distributed immediately if desired but this is __not
recommended__ for anything but testing.  You will want to configure a background processor to handle activity distribution.
Out of the box Seymour supports resque for activity distribution but other systems (e.g. DelayedJob) could easily be added.

## Installation

Add this line to your application's Gemfile:

    gem 'seymour'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install seymour

## Usage

### Define your activities

Seymour Activities are based loosely on the Activity Streams 1.0 specification (http://activitystrea.ms).

Activities in Seymour consist of an Actor, a Type (replaces Verb from the spec), an Object (optional but encouraged), and a Target (optional).

All Seymour Activities inherit from a base Activity class which you must define.  Inheritance is used so that
all Activities can be stored in a single mongodb collection and so that we can more easily render views of
activity items based on class name (e.g. `render @actvities` would work and find the appropriate partials for
each type of Activity).


Here is an example of a minimal base Seymour Activity.
``` ruby
class Activities::Activity
	include Seymour::Activity
end
```

You can name your Activity class anything that works for you.  You must include Seymour::Activity in your base Activity
(which automatically sets Mongoid up for you).

class Activities::NewComment < Activities::Activity
	actor :comment_author, cache: [:full_name, :slug]
	object :comment, cache: [:content]
	target :post, cache: [:title, :slug]
end

Your Activities do not need to be namespaced as above.

### Activity Delivery

All Activities in Seymour are persisted in the collection of your base Activity class (where you included Seymour::Activity).  Once an
Activity is persisted, it will be delivered automatically to its defined channels and recipients if configured.  If no delivery channels
are defined for an activity then it is simply persisted as an activity which could be used for a global activity feed or to generate
a list an Actor's activity.

Seymour comes with one pre-defined delivery channel:  Feed.  The Feed delivery channel takes its list of recipients and saves copies
of the Activity to each of their feeds.  The recipients can be any Actor you have configured.  Actually it can be any model you want but
only defined Actors will be easily retrievable.

Delivery channels are configured like this:

``` ruby
class Activities::NewComment < Activities::Activity
	actor :comment_author, cache: [:full_name, :slug]
	object :comment, cache: [:content]
	target :post, cache: [:title, :slug]
  deliver_to :feed, recipients: -> activity {activity.comment_author.followers}
  deliver_to :email
end
```

The first parameter to deliver_to is the name of the channel.  Channel names must be unique.  The Channel name for the Feed channel
is :feed.

Additionally, default recipients can be specified for a distribution channel by providing a proc that returns an array of Actors that
should receive the Activity via that channel.

Recipients can be overridden when publishing an activity.  If no default recipients are specified then it is expected that they are
provided as a parameter to publishing.

Additionaly options may be available depending on the specific delivery channel.

### Setup Actors

Actors in Seymour can be any Mongoid model in your system.

``` ruby
class User
    include Mongoid::Document
    include Seymour::Actor

    field :full_name, :type => String

    def followers
        User.excludes(:id => self.id).all
    end
end
```

Just make sure you include the Seymour::Actor module to give it the appropriate helper methods.

### Publishing Activities

Wherever appropriate for your app (controller, observer, etc):

``` ruby
actor.publish_activity(:new_comment, object: comment, target: post, email: {recipients: actor})
```

This will use the configured distribution system to begin delivering the activity.  Typically this will be some sort of background
job system.  The distribution mechanism will persist the Activity specified by the first parameter (:new_comment) and will then proceed
to deliver the Activity as it is configured.

Remember, the recipients for any delivery channel can be overridden in the call to publish_activity.

``` ruby
actor.publish_activity(:new_comment, object: comment, target: post, feed: {recipients: []}, email: {recipients: actor})
```

This would prevent any feed items from being created for this activity.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
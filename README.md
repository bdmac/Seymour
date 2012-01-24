# Seymour

Feed me Seymour!  Feed Seymour activities and it will distribute them as needed.

Seymour is flexible in its distribution mechanism and allows for multiple delivery channels to be configured based on
activity type.  A delivery channel is a mechanism for alerting an actor (typically a user) of a new activity.  Seymour
only comes with a Feed delivery channel but is easily extended to add others such as email, iOS push notifications, or
SMS messages.

For activity storage and feed distribution only mongodb and the Mongoid ODM is currently supported.

Seymour uses a fan out on write approach to activity distribution and delivery.  It does not provide any mechanisms for
refining the feed, it simply distributes activities to appropriate parties via defined channels.

Seymour supports several distribution mechanisms for delivering activities to recipients.  Activities _can_ be distributed
immediately if desired but this is __not recommended__ for anything but testing.  You will want to configure a background
processor to handle activity distribution. Out of the box Seymour supports resque for activity distribution but other 
systems (e.g. DelayedJob) could easily be added and used.

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

Activities in Seymour consist of four elements: an Actor, a Type (replaces Verb from the spec), an Object (optional but encouraged), and a Target (optional).

All Seymour Activities inherit from a base class which includes Seymour::ActivityDocument.  You may either inherit from the provided
Seymour::Models::Activity class or define your own base class that includes Seymour::ActivityDocument.  Inheritance is used so that
all Activities can be stored in a single mongodb collection and so that we can more easily render views of
activity items based on class name (e.g. `render @actvities` would work and find the appropriate partials for
each type of Activity).


Here is an example of a minimal base Seymour Activity should you want to define your own.
``` ruby
class Activities::Activity
	include Seymour::ActivityDocument
end
```

You can name your Activity class anything that works for you.  You must include Seymour::ActivityDocument in your base Activity
(which automatically sets Mongoid up for you).

You would then setup subclasses of your base Activity to define your activities.

``` ruby
class Activities::NewComment < Activities::Activity
  register_activity
  define_actor  :comment_author, cache: [:full_name, :slug]
  define_object :comment, cache: [:content], required: true
  define_target :post, cache: [:title, :slug], class: Post
  
  deliver_to :feed, recipients: -> activity {activity.comment_author.followers}
end
```

Note the call to register_activity above.  This is currently needed to alert Seymour of your various Activity subclasses.  This may not
be required in future versions of Seymour.

The Type of an Activity is defined by its subclass.  That leaves Actor, Object, and Target to be defined.  Only Actor is actually required
in your subclass.  The definition takes two parameters.

The first parameter is the definition alias.  The alias provides a hint as to what type of Mongoid document is being stored.  It automatically
sets up a Mongoid field-level alias and does not need to map to any actual class in your application.  In the above example we are storing a
Comment as the Object on the Activity.  The alias allows us to access the Comment in one of two ways:

``` ruby
activity.object => Comment
activity.comment => Comment
```

The second parameter is an options hash.  The allowed keys are:
* cache: Fields/method results to be cached on the Activity.  Accessing these fields will NOT require an additional query.  Accessing any other
fields on the model will need to query the DB to load the model.
* required: If set to true, adds a validation that the element is present.  This is always true for Actor.
* class:  Sets up a class type restriction on the element.  By default Seymour will allow any type of object to be stored for any element.
Setting a class requirement will cause Seymour to throw a Seymour::InvalidData error if the model object for an element does not match the
specified class.

Activities support namespaces but do not require them.

Activities fully support storing embedded documents as Activity elements.

### Distribution

Seymour supports a flexible Activity distribution mechansim.  There are two distributors included with Seymour:  `Seymour::Distribution::Immediate`
and `Seymour::Distribution::Resque`.

Immediate distribution does what it sounds like.  It immediately distributes the Activity across all configured channels.  This will block
your application and is really not recommended for anything but testing purposes or the simplest of installations.

Resque distribution will offload distribution onto your background resque queue thus allowing your application to continue responding to requests.
This is the preferred default distribution mechanism.

If neither of these distribution mechanisms are suitable for your application you can easily add and use your own distributor.  You simply define
a new class in Seymour::Distributors that responds to `distribute(activity, channel_options = {})` and configure Seymour to use it.

``` ruby
module Seymour
  module Distributors
    class DelayedJob
      def self.distribute(activity, channel_options = {})
        Seymour::Channels.channels(channel_options).each do |channel|
          channel.deliver(activity)
        end
      end
      handle_asynchronously :distribute # DelayedJob method
    end
  end
end

# In your seymour.rb initializer
Seymour.configure do |config|
    config.distribution = :delayed_job
end
```

### Delivery (Channels)

All Activities in Seymour are persisted in the collection of your base Activity class (where you included Seymour::ActivityDocument).  Once an
Activity is persisted, it will be distributed automatically to its defined channels if so configured.  If no delivery channels
are defined for an activity then it is simply persisted as an activity which could be used for a global activity feed or to generate
a list an Actor's activity.

Seymour comes with one pre-defined delivery channel:  Feed.  The Feed delivery channel takes its list of recipients and updates each of their
feeds with the activity being distributed.  The recipients can be any Actor you have configured.

Delivery channels are configured like this:

``` ruby
class Activities::NewComment < Activities::Activity
  register_activity
  define_actor  :comment_author, cache: [:full_name, :slug]
  define_object :comment, cache: [:content], required: true
  define_target :post, cache: [:title, :slug], class: Post
  
  # Configure delivery channels
  deliver_to :feed, recipients: -> activity {activity.comment_author.followers}
end
```

The first parameter to deliver_to is the name of the channel.  Channel names must be unique and must match a known channel in the Seymour::Channels
namespace.  The Channel name for the Feed channel would be :feed.

Additionally, default recipients can be specified for a distribution channel by providing a proc that returns an array of Actors that
should receive the Activity via that channel.  The proc will receive the Activity being delivered as its sole argument.

Recipients can be overridden when publishing an activity (see Publishing Activities below).  If no default recipients are specified then it is expected that they are
provided as a parameter to publishing.

Additionaly options may also be available depending on the specific delivery channel.

Adding additional delivery channels to Seymour is easy.

``` ruby
module Seymour
  module Channels
    class Email < Base
      def deliver(activity)
        recipients = recipients(activity)
        return unless recipients
        recipients.each do |recipient|
          # Deliver email to recipient based on activity type.
        end
      end
    end
  end
end

# In your seymour.rb initializer
Seymour.configure do |config|
    config.channels = [:feed, :email]
end
```

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

Wherever appropriate for your app (controller, observer, model callback, etc.):

``` ruby
actor.publish_activity(:new_comment, object: comment, target: post)
```

This will use the configured distribution system to begin delivering the activity.  Typically this will be some sort of background
job system.  The distribution mechanism will persist the Activity specified by the first parameter (:new_comment) and will then proceed
to deliver the Activity as it is configured.

Remember, the recipients for any delivery channel can be overridden in the call to publish_activity:

``` ruby
actor.publish_activity(:new_comment, object: comment, target: post, feed: {recipients: []}, email: {recipients: actor})
```

This would prevent any feed items from being created for this activity and email the actor about the activity.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Inspiration

Seymour was originally inspired by the [Streama Gem](https://github.com/christospappas/streama).  Streama did not quite work for my
needs though so I began work on this gem instead.  Many of the core concepts are inspired by Streama.
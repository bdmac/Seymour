require "spec_helper"

describe Seymour::Actor do
  let(:actor) { User.create(full_name: "Brian McManus") }
  let(:post) { Post.create(title: "The Title", user: actor) }
  let(:activity) { Activities::NewPost.create(author: actor, post: post) }

  describe ".publish_activity" do
    it "should create an activity with itself configured as the actor" do
      actor.publish_activity(:new_post, post: post)
      activity = Activities::Activity.last
      activity.load_instance(:author).should == actor
    end

    it "should add the activity to the actor's outgoing feed" do
      activity = actor.publish_activity(:new_post, post: post)
      actor.outgoing_activity_stream.should include(activity)
    end
  end

  describe ".add_activity_to_feed!" do
  	it "should add the activity to the actor's incoming feed" do
	  	actor.add_activity_to_feed!(activity)
	  	actor.incoming_activity_stream.should include(activity)
	  end
  end
end
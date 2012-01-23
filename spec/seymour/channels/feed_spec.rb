require "spec_helper"

describe Seymour::Channels::Feed do
  describe ".deliver" do
    it "adds the activity to the recipients' feeds" do
      post = Post.create(title: "Super Post")
      commenter = User.create(full_name: "Someone Else")
      feed_options = {recipients: [User.create(full_name: "Brian McManus"), post]}
      activity = Activities::NewComment.create(actor: commenter, comment: Comment.create(post: post, user: commenter))
      channel = Seymour::Channels::Feed.new(feed_options)
      channel.deliver(activity)
      feed_options[:recipients].each do |recipient|
        recipient.incoming_activity_stream.count.should == 1
      end
    end
  end
end
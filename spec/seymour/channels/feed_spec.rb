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

    it "does not add the activity to the actor's feed" do
      post = Post.create(title: "Super Post")
      commenter = User.create(full_name: "Someone Else")
      feed_options = {recipients: [commenter]}
      activity = Activities::NewComment.create(actor: commenter, comment: Comment.create(post: post, user: commenter))
      channel = Seymour::Channels::Feed.new(feed_options)
      channel.deliver(activity)
      commenter.incoming_activity_stream.should_not include(activity)
    end

    it "raises invalid recipients unless the recipients respond to :each" do
      feed_options = {recipients: 'BAD RECIPIENTS'}
      activity = Activities::NewPost.create(actor: User.create(full_name: "Brian"), post: Post.create(title: "Something"))
      channel = Seymour::Channels::Feed.new(feed_options)
      expect {
        channel.deliver(activity)
      }.to raise_error(Seymour::InvalidRecipients)
    end
  end
end
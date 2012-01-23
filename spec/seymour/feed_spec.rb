require "spec_helper"

describe Seymour::Models::Feed do
  let(:feed_owner) { User.create(full_name: "Brian McManus") }
  describe "ownership" do
    describe "polymorphism" do
      it "allows Users to have a feed" do
        feed = Seymour::Models::Feed.create(owner: feed_owner)
        feed.owner.should == feed_owner
      end

      it "allows Posts to have a feed" do
        post = Post.create(title: "Great Post")
        feed = Seymour::Models::Feed.create(owner: post)
        feed.owner.should == post
      end
    end

    it "allows one feed per owner" do
      Seymour::Models::Feed.create(owner: feed_owner)
      expect { Seymour::Models::Feed.create!(owner: feed_owner) }.to raise_error
    end
  end

  describe "feed items" do
    describe "polymorphism" do
      it "allows NewPost feed items" do
        feed = Seymour::Models::Feed.create(owner: feed_owner)
        activity = Activities::NewPost.create(author: feed_owner, post: Post.create(title: "Some Title"))
        feed.feed_items << activity
        feed.feed_items.first.should == activity
      end

      it "allows NewComment feed items" do
        feed = Seymour::Models::Feed.create(owner: feed_owner)
        post = Post.create(title: "Some Title")
        comment = post.comments.create(content: "A comment")
        activity = Activities::NewComment.create(comment_author: feed_owner, post: post, comment: comment)
        feed.feed_items << activity
        feed.feed_items.first.should == activity
      end

      it "allows mixed feed items" do
        feed = Seymour::Models::Feed.create(owner: feed_owner)
        post = Post.create(title: "Some Title")
        comment = post.comments.create(content: "A comment")
        post_activity = Activities::NewPost.create(author: feed_owner, post: post)
        comment_activity = Activities::NewComment.create(comment_author: feed_owner, post: post, comment: comment)
        feed.feed_items << post_activity
        feed.feed_items << comment_activity
        feed.reload
        feed.feed_items.should == [comment_activity, post_activity]
      end
    end
  end
end
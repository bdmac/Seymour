require 'spec_helper'

describe Seymour::Models::Activity do
  let(:user) { User.create(full_name: "Brian McManus", name: "Brian") }

  # TODO Should be a better way of ensuring this happens...
  it 'registers the activity class' do
    Seymour::ActivityRegistry.find(:new_comment).should == Activities::NewComment
  end

  describe 'includes DSL method' do
    it 'responding to #define_actor' do
      Activities::Activity.should respond_to(:define_actor)
    end
    it 'responding to #defined_actor' do
      Activities::Activity.should respond_to(:defined_actor)
    end
    it 'responding to #define_object' do
      Activities::Activity.should respond_to(:define_object)
    end
    it 'responding to #define_target' do
      Activities::Activity.should respond_to(:define_activity_target)
    end
    it 'responding to #deliver_to' do
      Activities::Activity.should respond_to(:deliver_to)
    end
  end

  describe "#refresh" do
    before(:each) { Activities::NewPost.create(actor: user) }
    
    it "reloads instances and updates activities stored data" do
      activity = Activities::Activity.last    
      
      expect do
        user.update_attribute(:full_name, "Test")
        activity.refresh_data
      end.to change{ activity.actor['full_name'] }.from("Brian McManus").to("Test")
    end
  end

  describe "persist with embedded documents" do
    it "works with directly embedded" do
      post = Post.create(title: "Some Title")
      comment = post.comments.create(content: "A comment")
      activity = Activities::NewComment.create(comment_author: user, post: post, comment: comment)
      activity.load_instance(:comment).should == comment
    end

    it "works with nested embeds" do
      post = Post.create(title: "Some Title")
      comment = post.comments.create(content: "A comment")
      like = comment.likes.create
      activity = Activities::NewLike.create(liker: user, like: like, comment: comment)
      activity.load_instance(:like).should == like
      activity.load_instance(:comment).should == comment
    end
  end

  it 'allows direct access to cached data' do
    activity = Activities::NewPost.create(actor: user)
    activity.actor.full_name == 'Brian McManus'
  end

  it 'automatically loads the model if uncached call is made' do
    activity = Activities::NewPost.create(actor: user)
    activity.reload
    activity.actor.followers.should == User.all
  end

  it 'allows direct access to cached name' do
    post = Post.create(title: "Some Title")
    comment = post.comments.create(content: "A comment")
    like = comment.likes.create
    activity = Activities::NewLike.create(liker: user, like: like, comment: comment)
    activity.liker.name == 'Brian'
  end
end
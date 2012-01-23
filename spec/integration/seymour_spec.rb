require "spec_helper"

describe "Seymour" do
  let(:actor) { User.create(full_name: "Brian McManus", slug: "brian-mcmanus") }
  let(:post) { Post.create(title: "Great Post", body: "It sure is.", slug: "great-post", user: actor) }
  let(:comment) { post.comments.create(content: "What a great post...", user: actor) }

  describe "publish activity from an actor" do
    describe "immediate distribution" do
      it "should save an Activity record" do
        expect {
          activity = actor.publish_activity(:new_comment, comment: comment)
        }.to change(Activities::Activity, :count).by(1)
      end

      it "should return the appropriate Activity type" do
        actor.publish_activity(:new_comment, comment: comment).should be_kind_of Activities::NewComment
      end

      it "should deliver the Activity appropriately" do
      end
    end

    describe "resque distribution" do
      before(:all) { Seymour::Config.distribution = :resque }
      after(:all)  { Seymour::Config.distribution = :immediate }
    end
  end
end
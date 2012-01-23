require "spec_helper"

describe Seymour::Distribution::Immediate do
  let(:distributor) { described_class }
  let(:user) { User.create(full_name: "Brian McManus") }
  let(:activity) {Activities::NewPost.new}

  describe "#distribute" do
    it "should distribute the activity as specified by the channel options" do
      channel_options = {
        feed: { recipients: "me@me.com" }
      }
      Seymour::Channels::Feed.any_instance.should_receive(:deliver).with(activity)
      distributor.distribute(activity, channel_options)
    end
  end
end
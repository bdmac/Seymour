require "spec_helper"

describe Seymour::ActivityRegistry do
  let(:registry) do
    described_class
  end

  describe "#register" do
    it "registers the provided Activity class" do
      registry.register(Activities::Activity).should == :activity
    end

    it "raises an exception when registering a non-Activity class" do
      expect { registry.register(User) }.to raise_error(Seymour::InvalidActivity)
    end
  end

  describe "#find" do
    before(:each) do
      registry.register(Activities::Activity)
    end

    it "finds a registered Activity" do
      registry.find(:activity).should == Activities::Activity
    end

    it "finds descendants of a registere Activity" do
      registry.find(:new_comment).should == Activities::NewComment
    end

    it "raises an exception if it cannot find an Activity for a verb" do
      expect { registry.find(:bad_activity) }.to raise_error(Seymour::InvalidActivity)
    end
  end
end
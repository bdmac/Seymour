require "spec_helper"

describe Seymour::Channels::Base do
  it "accepts an options hash" do
    channel = Seymour::Channels::Base.new(key: "value")
    channel.options[:key].should == "value"
  end

  it "responds to deliver" do
    Seymour::Channels::Base.new.should respond_to :deliver
  end
end
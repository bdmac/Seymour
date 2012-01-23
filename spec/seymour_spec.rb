require "spec_helper"

describe Seymour do
  let(:user) { User.create(full_name: "Brian McManus") }

  describe '#configure' do
    it 'takes a block to allow configuration' do
      Seymour.configure do |config|
        config.activity_collection = :testing
      end
      Seymour::Config.activity_collection.should == :testing
    end
  end

  describe '#publish' do
    it 'initializes and distributes the activity' do
      data = {actor: user}
      Seymour::Distribution.should_receive(:distribute)
      Seymour.publish(:new_post, data).class.should include(Seymour::ActivityDocument)
    end
  end
end
require "spec_helper"

describe Seymour::Distribution do
  let(:activity) {Activities::NewPost.new}

  describe '#distributor' do
    after(:each) do
      Seymour::Config.distribution = :immediate
    end

    it 'uses the default distributor' do
      Seymour::Distribution.distributor.should == Seymour::Distribution::Immediate
    end

    it 'uses the configured distributor' do
      Seymour::Config.distribution = :resque
      Seymour::Distribution.distributor.should == Seymour::Distribution::Resque
    end
  end

  describe '#distribute' do
    it 'calls distribute on the configured distributor with the activity and specified channel options' do
      channel_options = stub
      Seymour::Distribution::Immediate.should_receive(:distribute).with(activity, channel_options)
      Seymour::Distribution.distribute(activity, channel_options)
    end
  end
end
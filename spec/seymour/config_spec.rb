require "spec_helper"

describe Seymour::Config do
  let(:config) do
    described_class
  end

  describe '#option' do
    it 'creates accessors for the option' do
      config.option(:testing)
      config.should respond_to(:testing)
      config.should respond_to(:testing?)
      config.should respond_to(:testing=)
    end

    it 'sets the value' do
      config.option(:testing, default: true)
      config.testing.should == true
    end

    it 'allows the option value to change' do
      config.option(:testing, default: true)
      config.testing = false
      config.testing.should == false
    end
  end
end
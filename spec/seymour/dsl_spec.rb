require "spec_helper"

describe Seymour::DSL do
  let(:dsl) do
    Class.new do
      include Mongoid::Document
      extend Seymour::DSL
    end
  end

  describe '#define_actor' do
    it 'should set basic data for the actor' do
      dsl.define_actor(:author)
      dsl.defined_actor.should == {alias: :author, cache: [], class: nil}
    end
    
    it 'should configure cache options for the actor' do
      dsl.define_actor(:author, cache: [:slug, :full_name])
      dsl.defined_actor.should == {alias: :author, cache: [:slug, :full_name], class: nil}
    end

    it 'should set a class restriction on the actor' do
      dsl.define_actor(:author, class: User)
      dsl.defined_actor.should == {alias: :author, cache: [], class: User}
    end

    it 'should set an alias to access the actor' do
      dsl.define_actor(:author)
      impl = dsl.new
      impl.author = 42
      impl.actor.should == 42
    end
  end
end
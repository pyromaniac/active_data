# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model do
  let(:model) do
    Class.new do
      include ActiveData::Model

      attribute :name
      attribute :count, default: 0
    end
  end

  specify { expect { model.blablabla }.to raise_error NoMethodError }
  specify { model.i18n_scope.should == :active_data }
  specify { model.new.should_not be_persisted }
  specify { model.instantiate({}).should be_an_instance_of model }
  specify { model.instantiate({}).should be_persisted }

  context 'Fault tolerance' do
    specify{ expect { model.new(foo: 'bar') }.not_to raise_error }
  end

  describe '#instantiate' do
    context do
      subject(:instance) { model.instantiate(name: 'Hello', foo: 'Bar') }

      specify { subject.instance_variable_get(:@attributes).should == { name: 'Hello', count: nil }.stringify_keys }
    end
  end

  describe '#==' do
    subject { model.new name: 'hello', count: 42 }
    it { should_not == nil }
    it { should_not == 'hello' }
    it { should_not == Object.new }
    it { should_not == model.new }
    it { should_not == model.new(name: 'hello1', count: 42) }
    it { should_not == model.new(name: 'hello', count: 42.1) }
    it { should == model.new(name: 'hello', count: 42) }
  end
end

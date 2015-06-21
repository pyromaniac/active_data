# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model do
  let(:model) do
    stub_model do
      attribute :name
      attribute :count, default: 0
    end
  end

  specify { expect { model.blablabla }.to raise_error NoMethodError }

  context 'Fault tolerance' do
    specify{ expect { model.new(foo: 'bar') }.not_to raise_error }
  end

  describe '#==' do
    subject { model.new name: 'hello', count: 42 }
    it { is_expected.not_to eq(nil) }
    it { is_expected.not_to eq('hello') }
    it { is_expected.not_to eq(Object.new) }
    it { is_expected.not_to eq(model.new) }
    it { is_expected.not_to eq(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eq(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eq(model.new(name: 'hello', count: 42)) }
  end
end

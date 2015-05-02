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

  specify { expect([model].flatten).to eq([model]) }
  specify { expect { model.blablabla }.to raise_error NoMethodError }
  specify { expect(model.i18n_scope).to eq(:active_data) }
  specify { expect(model.new).not_to be_persisted }
  specify { expect(model.instantiate({})).to be_an_instance_of model }
  specify { expect(model.instantiate({})).to be_persisted }

  context 'Fault tolerance' do
    specify{ expect { model.new(foo: 'bar') }.not_to raise_error }
  end

  describe '#instantiate' do
    context do
      subject(:instance) { model.instantiate(name: 'Hello', foo: 'Bar') }

      specify { expect(subject.instance_variable_get(:@attributes)).to eq({ name: 'Hello', count: nil }.stringify_keys) }
    end
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

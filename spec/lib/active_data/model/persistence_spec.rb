require 'spec_helper'

describe ActiveData::Model::Persistence do
  let(:model) do
    stub_model do
      include ActiveData::Model::Persistence

      attribute :name
      attribute :count, default: 0
    end
  end

  specify { expect(model.new).not_to be_persisted }
  specify { expect(model.new).not_to be_destroyed }

  describe '#instantiate' do
    specify { expect(model.instantiate({})).to be_an_instance_of model }
    specify { expect(model.instantiate({})).to be_persisted }
    specify { expect(model.instantiate({})).not_to be_destroyed }

    context do
      subject(:instance) { model.instantiate(name: 'Hello', foo: 'Bar') }

      specify { expect(subject.instance_variable_get(:@initial_attributes)).to eq({name: 'Hello'}.stringify_keys) }
    end
  end

  describe '#instantiate_collection' do
    context do
      subject(:instances) { model.instantiate_collection(name: 'Hello', foo: 'Bar') }

      specify { expect(subject).to be_a Array }
      specify { expect(subject.first.instance_variable_get(:@initial_attributes)).to eq({name: 'Hello'}.stringify_keys) }
    end

    context do
      before { model.send(:include, ActiveData::Model::Scopes) }
      subject(:instances) { model.instantiate_collection([{name: 'Hello', foo: 'Bar'}, {name: 'World'}]) }

      specify { expect(subject).to be_a ActiveData::Model::Scopes::ScopeProxy }
      specify { expect(subject.count).to eq(2) }
      specify { expect(subject.first.instance_variable_get(:@initial_attributes)).to eq({name: 'Hello'}.stringify_keys) }
      specify { expect(subject.second.instance_variable_get(:@initial_attributes)).to eq({name: 'World'}.stringify_keys) }
    end
  end
end

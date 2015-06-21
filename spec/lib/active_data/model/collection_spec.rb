# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Collection do
  let(:model) do
    stub_model do
      include ActiveData::Model::Collection

      attribute :name

      def self.except_first
        self[1..-1]
      end

      def self.no_mars
        delete_if { |i| i.name == 'Mars' }
      end
    end
  end

  let(:collectionize_hash) do
    stub_model do
      include ActiveData::Model::Collection
      collectionize Hash
    end
  end

  describe '.collection_class' do
    specify { expect(model.collection_class).to be < Array }
    specify { expect(model.collection_class.collectible).to eq(model) }
    specify { expect(model.collection_class.new).to be_empty }

    specify { expect(collectionize_hash.collection_class).to be < Hash }
    specify { expect(collectionize_hash.collection_class.collectible).to eq(collectionize_hash) }
    specify { expect(collectionize_hash.collection_class.new).to be_empty }
  end

  describe '.collection' do
    let(:collection) { model.collection([model.new(name: 'Hello'), model.new(name: 'World'), model.new(name: 'Mars')]) }

    specify { expect(collection).to be_instance_of model.collection_class }
    specify { expect { model.collection([model.new(name: 'Hello'), {}]) }.to raise_error ActiveData::AssociationTypeMismatch }

    context 'scopes' do
      specify { expect(collection.except_first).to be_instance_of model.collection_class }
      specify { expect(collection.no_mars).to be_instance_of model.collection_class }
      specify { expect(collection.except_first).to eq(model.collection([model.new(name: 'World'), model.new(name: 'Mars')])) }
      specify { expect(collection.no_mars).to eq(model.collection([model.new(name: 'Hello'), model.new(name: 'World')])) }
      specify { expect(collection.except_first.no_mars).to eq(model.collection([model.new(name: 'World')])) }
      specify { expect(collection.no_mars.except_first).to eq(model.collection([model.new(name: 'World')])) }
    end
  end

  context do
    let!(:ancestor) do
      stub_model do
        include ActiveData::Model::Collection
      end
    end

    let!(:descendant1) do
      Class.new ancestor
    end

    let!(:descendant2) do
      Class.new ancestor
    end

    specify { expect(descendant1.collection_class).to be < Array }
    specify { expect(descendant2.collection_class).to be < Array }
    specify { expect(ancestor.collection_class).not_to eq(descendant1.collection_class) }
    specify { expect(descendant1.collection_class).not_to eq(descendant2.collection_class) }
  end
end

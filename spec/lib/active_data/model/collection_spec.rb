# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Collection do
  let(:klass) do
    Class.new do
      include ActiveData::Model

      attribute :name

      def self.except_first
        self[1..-1]
      end

      def self.no_mars
        delete_if { |i| i.name == 'Mars' }
      end
    end
  end

  class CollectionizableTest
    include ActiveData::Model
  end

  let(:collection) { klass.instantiate_collection([{ name: 'Hello' }, { name: 'World' }, { name: 'Mars' }]) }

  specify { expect(klass.collection_class).not_to be_nil }
  specify { expect(klass.collection_class.collectible).to eq(klass) }
  specify { expect(klass.collection_class.new).to be_empty }
  specify { expect(CollectionizableTest.collection_class).to be < Array }

  specify { expect(collection).to be_instance_of klass.collection_class }
  specify { expect(collection.except_first).to be_instance_of klass.collection_class }
  specify { expect(collection.no_mars).to be_instance_of klass.collection_class }
  specify { expect(collection.except_first).to eq(klass.instantiate_collection([{ name: 'World' }, { name: 'Mars' }])) }
  specify { expect(collection.no_mars).to eq(klass.instantiate_collection([{ name: 'Hello' }, { name: 'World' }])) }
  specify { expect(collection.except_first.no_mars).to eq(klass.instantiate_collection([{ name: 'World' }])) }
  specify { expect(collection.no_mars.except_first).to eq(klass.instantiate_collection([{ name: 'World' }])) }

  context do
    let!(:ancestor) do
      Class.new do
        include ActiveData::Model
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

# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Collectionizable do
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

  specify { klass.collection_class.should_not be_nil }
  specify { klass.collection_class.collectible.should == klass }
  specify { klass.collection_class.new.should be_empty }
  specify { CollectionizableTest.collection_class.should < Array }

  specify { collection.should be_instance_of klass.collection_class }
  specify { collection.except_first.should be_instance_of klass.collection_class }
  specify { collection.no_mars.should be_instance_of klass.collection_class }
  specify { collection.except_first.should == klass.instantiate_collection([{ name: 'World' }, { name: 'Mars' }]) }
  specify { collection.no_mars.should == klass.instantiate_collection([{ name: 'Hello' }, { name: 'World' }]) }
  specify { collection.except_first.no_mars.should == klass.instantiate_collection([{ name: 'World' }]) }
  specify { collection.no_mars.except_first.should == klass.instantiate_collection([{ name: 'World' }]) }

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

    specify { descendant1.collection_class.should < Array }
    specify { descendant2.collection_class.should < Array }
    specify { ancestor.collection_class.should_not == descendant1.collection_class }
    specify { descendant1.collection_class.should_not == descendant2.collection_class }
  end
end

# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations do

  class NestedAssoc
    include ActiveData::Model

    attribute :name
  end

  context do
    let(:klass) do
      Class.new do
        include ActiveData::Model

        attribute :name
        embeds_one :assoc, class_name: NestedAssoc

        accepts_nested_attributes_for :assoc
      end
    end
    let(:instance) { klass.new(name: 'world') }

    context do
      before { instance.assoc_attributes = { name: 'foo'} }
      specify { instance.assoc.should be_instance_of NestedAssoc }
      specify { instance.assoc.name.should == 'foo' }
    end
  end

  context do
    let(:klass) do
      Class.new do
        include ActiveData::Model

        attribute :name
        embeds_many :assocs, class_name: NestedAssoc

        accepts_nested_attributes_for :assocs
      end
    end
    let(:instance) { klass.new(name: 'world') }

    context do
      before { instance.assocs_attributes = [{ name: 'foo' }, { name: 'bar' }] }
      specify { instance.assocs.count.should == 2 }
      specify { instance.assocs.first.name.should == 'foo' }
      specify { instance.assocs.last.name.should == 'bar' }
    end

    context do
      before { instance.assocs_attributes = {1 => { name: 'baz' }, 2 => { name: 'foo' }} }
      specify { instance.assocs.count.should == 2 }
      specify { instance.assocs.first.name.should == 'baz' }
      specify { instance.assocs.last.name.should == 'foo' }
    end
  end
end

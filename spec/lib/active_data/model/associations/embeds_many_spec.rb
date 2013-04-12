# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsMany do

  class ManyAssoc
    include ActiveData::Model

    attribute :name
  end

  let(:klass) do
    Class.new do
      include ActiveData::Model

      attribute :name
      embeds_many :many_assocs
    end
  end

  let(:instance) { klass.new(:name => 'world') }

  context do
    specify { instance.many_assocs.should be_empty }
    specify { instance.many_assocs.should be_instance_of ManyAssoc.collection_class }
    specify { instance.many_assocs.count.should == 0 }
  end

  context 'accessor with objects' do
    before { instance.many_assocs = [ManyAssoc.new(name: 'foo'), ManyAssoc.new(name: 'bar')] }
    specify { instance.many_assocs.count.should == 2 }
    specify { instance.many_assocs[0].name.should == 'foo' }
    specify { instance.many_assocs[1].name.should == 'bar' }
  end

  context 'accessor with attributes' do
    before { instance.many_assocs = [{ name: 'foo' }, { name: 'bar' }] }
    specify { instance.many_assocs.count.should == 2 }
    specify { instance.many_assocs[0].name.should == 'foo' }
    specify { instance.many_assocs[1].name.should == 'bar' }
  end

  describe '#instantiate' do
    subject(:instance) { klass.instantiate name: 'Root', many_assocs: [{ name: 'foo' }, { name: 'bar' }] }

    its('many_assocs.count') { should == 2 }
  end
end

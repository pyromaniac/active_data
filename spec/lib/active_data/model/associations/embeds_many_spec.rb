# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsMany do

  class ManyAssoc
    include ActiveData::Model

    attribute :name
  end

  let(:noassoc) do
    Class.new do
      include ActiveData::Model

      attribute :name
    end
  end

  let(:klass) do
    Class.new(noassoc) do
      embeds_many :many_assocs
    end
  end

  let(:inherited1) do
    Class.new(klass) do
      embeds_many :many_assocs_inherited1, class_name: ManyAssoc
    end
  end

  let(:inherited2) do
    Class.new(noassoc) do
      embeds_many :many_assocs_inherited2, class_name: ManyAssoc
    end
  end

  subject { klass.new(name: 'world') }

  context do
    specify { subject.many_assocs.should be_empty }
    specify { subject.many_assocs.should be_instance_of ManyAssoc.collection_class }
    specify { subject.many_assocs.count.should == 0 }
  end

  context 'accessor with objects' do
    before { subject.many_assocs = [ManyAssoc.new(name: 'foo'), ManyAssoc.new(name: 'bar')] }
    specify { subject.many_assocs.count.should == 2 }
    specify { subject.many_assocs[0].name.should == 'foo' }
    specify { subject.many_assocs[1].name.should == 'bar' }
  end

  context 'accessor with attributes' do
    before { subject.many_assocs = [{ name: 'foo' }, { name: 'bar' }] }
    specify { subject.many_assocs.count.should == 2 }
    specify { subject.many_assocs[0].name.should == 'foo' }
    specify { subject.many_assocs[1].name.should == 'bar' }
  end

  context 'inheritance' do
    specify { noassoc.association_names.should == [] }
    specify { klass.association_names.should == %w(many_assocs) }
    specify { inherited1.association_names.should == %w(many_assocs many_assocs_inherited1) }
    specify { inherited2.association_names.should == %w(many_assocs_inherited2) }
  end

  describe '#instantiate' do
    subject { klass.instantiate name: 'Root', many_assocs: [{ name: 'foo' }, { name: 'bar' }] }

    its('many_assocs.count') { should == 2 }
  end

  describe '#==' do
    let(:instance) { klass.new(name: 'world') }
    before { subject.many_assocs = [ManyAssoc.new(name: 'foo'), ManyAssoc.new(name: 'bar')] }
    specify { subject.should_not == instance }

    context do
      before { instance.many_assocs = [ManyAssoc.new(name: 'foo')] }
      specify { subject.should_not == instance }
    end

    context do
      before { instance.many_assocs = [ManyAssoc.new(name: 'foo1'), ManyAssoc.new(name: 'bar')] }
      specify { subject.should_not == instance }
    end

    context do
      before { instance.many_assocs = [ManyAssoc.new(name: 'foo'), ManyAssoc.new(name: 'bar')] }
      specify { subject.should == instance }
    end
  end
end

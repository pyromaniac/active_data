# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes do

  let(:klass) do
    Class.new do
      include ActiveData::Model::Attributes
      attr_accessor :name

      attribute :id
      attribute :hello
      attribute :string, type: String, default_blank: true, default: ->(record){ record.name }
      attribute :count, type: Integer, default: 10
      attribute(:calc, type: Integer) { 2 + 3 }
      attribute :enum, type: Integer, enum: [1, 2, 3]
      attribute :enum_with_default, type: Integer, enum: [1, 2, 3], default: 2
      attribute :foo, type: Boolean, default: false

      def initialize name = nil
        @attributes = self.class.initialize_attributes
        @name = name
      end
    end
  end

  describe '.has_attribute?' do
    specify { klass.has_attribute?(:hello).should == true }
    specify { klass.has_attribute?('hello').should == true }
    specify { klass.has_attribute?(:name).should == false }
    specify { klass.has_attribute?(:foobar).should == false }
  end

  describe '#assign_attributes' do
    subject { klass.new('world') }
    let(:attributes) { { id: 42, hello: 'world', name: 'Ivan', missed: 'value' } }

    specify { expect { subject.assign_attributes(attributes) }.not_to change { subject.id } }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.hello } }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.name } }
  end

  context do
    subject { klass.new('world') }
    specify { klass.enum_values.should == [1, 2, 3] }
    its(:enum_values) { should == [1, 2, 3] }
    its(:string_default) { should == 'world' }
    its(:count_default) { should == 10 }
    its(:attributes) { should ==  { id: nil, hello: nil, count: 10, calc: 5, enum: nil, string: 'world', foo: false, enum_with_default: 2 }.stringify_keys  }
    its(:name) { should == 'world' }
    its(:hello) { should be_nil }
    its(:count) { should == 10 }
    its(:calc) { should == 5 }
    specify { expect { subject.hello = 'worlds' } .to change { subject.hello } .from(nil).to('worlds') }
    specify { expect { subject.count = 20 } .to change { subject.count } .from(10).to(20) }
    specify { expect { subject.calc = 15 } .to change { subject.calc } .from(5).to(15) }
  end

  context 'enums' do
    subject { klass.new('world') }

    specify { subject.enum = 3; subject.enum.should == 3 }
    specify { subject.enum = '3'; subject.enum.should == 3 }
    specify { subject.enum = 10; subject.enum.should == nil }
    specify { subject.enum = 'hello'; subject.enum.should == nil }
    specify { subject.enum_with_default = 3; subject.enum_with_default.should == 3 }
    specify { subject.enum_with_default = 10; subject.enum_with_default.should == 2 }
  end

  context 'attribute caching' do
    subject { klass.new('world') }

    context do
      before do
        subject.send(:attributes_cache).should_not_receive(:[])
      end

      specify { subject.hello }
    end

    context do
      before do
        subject.hello
        subject.send(:attributes_cache).should_receive(:[]).with('hello').once
      end

      specify { subject.hello }
    end

    context 'attribute cache reset' do
      before do
        subject.hello = 'blabla'
        subject.hello
        subject.hello = 'newnewnew'
      end

      specify { subject.hello.should == 'newnewnew' }
    end
  end

  context 'inheritance' do
    let!(:ancestor) do
      Class.new do
        include ActiveData::Model::Attributes
        attribute :foo
      end
    end

    let!(:descendant1) do
      Class.new ancestor do
        attribute :bar
      end
    end

    let!(:descendant2) do
      Class.new ancestor do
        attribute :baz
        attribute :moo
      end
    end

    specify { ancestor._attributes.keys.should == ['foo'] }
    specify { ancestor.instance_methods.should include :foo, :foo= }
    specify { ancestor.instance_methods.should_not include :bar, :bar=, :baz, :baz= }
    specify { descendant1._attributes.keys.should == ['foo', 'bar'] }
    specify { descendant1.instance_methods.should include :foo, :foo=, :bar, :bar= }
    specify { descendant1.instance_methods.should_not include :baz, :baz= }
    specify { descendant2._attributes.keys.should == ['foo', 'baz', 'moo'] }
    specify { descendant2.instance_methods.should include :foo, :foo=, :baz, :baz=, :moo, :moo= }
    specify { descendant2.instance_methods.should_not include :bar, :bar= }
  end
end

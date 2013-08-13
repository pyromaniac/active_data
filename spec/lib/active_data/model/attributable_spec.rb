# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributable do

  let(:klass) do
    Class.new do
      include ActiveData::Model::Attributable
      attr_reader :name

      attribute :hello
      attribute :string, type: String, default_blank: true, default: ->(record){ record.name }
      attribute :count, type: Integer, default: 10
      attribute(:calc, type: Integer) { 2 + 3 }
      attribute :enum, type: Integer, in: [1, 2, 3]
      attribute :enum_with_default, type: Integer, in: [1, 2, 3], default: 2
      attribute :foo, type: Boolean, default: false

      def initialize name = nil
        @attributes = self.class.initialize_attributes
        @name = name
      end
    end
  end

  context do
    subject { klass.new('world') }
    specify { klass.enum_values.should == Set.new([1, 2, 3]) }
    its(:attributes) { should ==  { hello: nil, count: 10, calc: 5, enum: nil, string: 'world', foo: false, enum_with_default: 2 }.stringify_keys  }
    its(:present_attributes) { should ==  { count: 10, calc: 5, string: 'world', foo: false, enum_with_default: 2 }.stringify_keys  }
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

  context 'calculating default values' do
    let(:klass) do
      Class.new do
        include ActiveData::Model::Attributable

        attribute(:rand, type: String) { SecureRandom.uuid }

        def initialize
          @attributes = self.class.initialize_attributes
        end
      end
    end

    subject { klass.new }
    specify { subject.rand.should == subject.rand }
    specify { subject.rand.should_not == klass.new.rand }
  end

  context 'default_blank' do
    let(:klass) do
      Class.new do
        include ActiveData::Model::Attributable

        attribute :string1, type: String, default_blank: true, default: 'default'
        attribute :string2, type: String, default: 'default'

        def initialize attributes = {}
          @attributes = self.class.initialize_attributes
          self.attributes = attributes
        end
      end
    end

    specify { klass.new.string1.should == 'default' }
    specify { klass.new.string2.should == 'default' }
    specify { klass.new(string1: '').string1.should == 'default' }
    specify { klass.new(string2: '').string2.should == '' }
    specify { klass.new(string1: 'hello').string1.should == 'hello' }
    specify { klass.new(string2: 'hello').string2.should == 'hello' }
  end

  context 'default_blank with boolean' do
    let(:klass) do
      Class.new do
        include ActiveData::Model::Attributable

        attribute :boolean1, type: Boolean, default_blank: true, default: true
        attribute :boolean2, type: Boolean, default: true
        attribute :boolean3, type: Boolean, default_blank: true, default: false
        attribute :boolean4, type: Boolean, default: false

        def initialize attributes = {}
          @attributes = self.class.initialize_attributes
          self.attributes = attributes
        end
      end
    end

    specify { klass.new.boolean1.should == true }
    specify { klass.new.boolean2.should == true }
    specify { klass.new.boolean3.should == false }
    specify { klass.new.boolean4.should == false }
    specify { klass.new(boolean1: '').boolean1.should == true }
    specify { klass.new(boolean2: '').boolean2.should == true }
    specify { klass.new(boolean3: '').boolean3.should == false }
    specify { klass.new(boolean4: '').boolean4.should == false }
    specify { klass.new(boolean1: false).boolean1.should == false }
    specify { klass.new(boolean2: false).boolean2.should == false }
    specify { klass.new(boolean3: false).boolean3.should == false }
    specify { klass.new(boolean4: false).boolean4.should == false }
    specify { klass.new(boolean1: true).boolean1.should == true }
    specify { klass.new(boolean2: true).boolean2.should == true }
    specify { klass.new(boolean3: true).boolean3.should == true }
    specify { klass.new(boolean4: true).boolean4.should == true }
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
        include ActiveData::Model::Attributable
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

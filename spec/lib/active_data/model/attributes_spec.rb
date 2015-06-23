# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes do

  let(:klass) do
    stub_class do
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
    specify { expect(klass.has_attribute?(:hello)).to eq(true) }
    specify { expect(klass.has_attribute?('hello')).to eq(true) }
    specify { expect(klass.has_attribute?(:name)).to eq(false) }
    specify { expect(klass.has_attribute?(:foobar)).to eq(false) }
  end

  describe '.inspect' do
    specify { expect(stub_model.inspect).to match(/\[anonymous model\]:\d+ \(no attributes\)/) }
    specify { expect(stub_model(:user).inspect).to eq('User (no attributes)') }
    specify { expect(stub_model { attribute :count, type: Integer; attribute :object }.inspect).to match(/\[anonymous model\]:\d+ \(count: Integer, object: Object\)/) }
    specify { expect(stub_model(:user) { attribute :count, type: Integer; attribute :object }.inspect).to match(/User \(count: Integer, object: Object\)/) }
  end

  describe '#assign_attributes' do
    subject { klass.new('world') }
    let(:attributes) { { id: 42, hello: 'world', name: 'Ivan', missed: 'value' } }

    specify { expect { subject.assign_attributes(attributes) }.not_to change { subject.id } }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.hello } }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.name } }
  end

  describe '#inspect' do
    specify { expect(stub_model.new.inspect).to match(/#<\[anonymous model\]:\d+:\d+ \(no attributes\)>/) }
    specify { expect(stub_model(:user).new.inspect).to match(/#<User:\d+ \(no attributes\)>/) }
    specify { expect(stub_model { attribute :count, type: Integer; attribute :object }.new.inspect).to match(/#<\[anonymous model\]:\d+:\d+ \(count: nil, object: nil\)>/) }
    specify { expect(stub_model(:user) { attribute :count, type: Integer; attribute :object }.new.inspect).to match(/#<User:\d+ \(count: nil, object: nil\)>/) }
  end

  context do
    subject { klass.new('world') }
    specify { expect(klass.enum_values).to eq([1, 2, 3]) }
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

    specify { subject.enum = 3; expect(subject.enum).to eq(3) }
    specify { subject.enum = '3'; expect(subject.enum).to eq(3) }
    specify { subject.enum = 10; expect(subject.enum).to eq(nil) }
    specify { subject.enum = 'hello'; expect(subject.enum).to eq(nil) }
    specify { subject.enum_with_default = 3; expect(subject.enum_with_default).to eq(3) }
    specify { subject.enum_with_default = 10; expect(subject.enum_with_default).to eq(2) }
  end

  context 'attribute caching' do
    subject { klass.new('world') }

    context do
      before do
        expect(subject.send(:attributes_cache)).not_to receive(:[])
      end

      specify { subject.hello }
    end

    context do
      before do
        subject.hello
        expect(subject.send(:attributes_cache)).to receive(:[]).with('hello').once
      end

      specify { subject.hello }
    end

    context 'attribute cache reset' do
      before do
        subject.hello = 'blabla'
        subject.hello
        subject.hello = 'newnewnew'
      end

      specify { expect(subject.hello).to eq('newnewnew') }
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

    specify { expect(ancestor._attributes.keys).to eq(['foo']) }
    specify { expect(ancestor.instance_methods).to include :foo, :foo= }
    specify { expect(ancestor.instance_methods).not_to include :bar, :bar=, :baz, :baz= }
    specify { expect(descendant1._attributes.keys).to eq(['foo', 'bar']) }
    specify { expect(descendant1.instance_methods).to include :foo, :foo=, :bar, :bar= }
    specify { expect(descendant1.instance_methods).not_to include :baz, :baz= }
    specify { expect(descendant2._attributes.keys).to eq(['foo', 'baz', 'moo']) }
    specify { expect(descendant2.instance_methods).to include :foo, :foo=, :baz, :baz=, :moo, :moo= }
    specify { expect(descendant2.instance_methods).not_to include :bar, :bar= }
  end
end

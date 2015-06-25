# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes do
  let(:model) do
    stub_model do
      include ActiveData::Model::Primary
      include ActiveData::Model::Associations

      primary_attribute
      attribute :full_name

      embeds_one(:embedded) {}
      embeds_many(:embeddeds) {}
    end
  end

  describe '.has_attribute?' do
    specify { expect(model.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.has_attribute?(:foobar)).to eq(false) }
  end

  describe '.attribute_names' do
    specify { expect(stub_model.attribute_names).to eq([])  }
    specify { expect(model.attribute_names).to eq(%w[id full_name embedded embeddeds]) }
    specify { expect(model.attribute_names(false)).to eq(%w[id full_name])  }
  end

  describe '.inspect' do
    specify { expect(stub_model.inspect).to match(/\[anonymous model\]:\d+ \(no attributes\)/) }
    specify { expect(stub_model(:user).inspect).to eq('User (no attributes)') }
    specify { expect(stub_model { attribute :count, type: Integer; attribute :object }.inspect).to match(/\[anonymous model\]:\d+ \(count: Integer, object: Object\)/) }
    specify { expect(stub_model(:user) { attribute :count, type: Integer; attribute :object }.inspect).to match(/User \(count: Integer, object: Object\)/) }
  end

  describe '#==' do
    let(:model) do
      stub_model do
        attribute :name
        attribute :count, default: 0
      end
    end
    subject { model.new name: 'hello', count: 42 }

    it { is_expected.not_to eq(nil) }
    it { is_expected.not_to eq('hello') }
    it { is_expected.not_to eq(Object.new) }
    it { is_expected.not_to eq(model.new) }
    it { is_expected.not_to eq(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eq(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eq(model.new(name: 'hello', count: 42)) }

    it { is_expected.not_to eql(nil) }
    it { is_expected.not_to eql('hello') }
    it { is_expected.not_to eql(Object.new) }
    it { is_expected.not_to eql(model.new) }
    it { is_expected.not_to eql(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eql(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eql(model.new(name: 'hello', count: 42)) }
  end

  describe '#has_attribute?' do
    specify { expect(model.new.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.new.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.new.has_attribute?(:foobar)).to eq(false) }
  end

  describe '#attribute_names' do
    specify { expect(stub_model.new.attribute_names).to eq([])  }
    specify { expect(model.new.attribute_names).to eq(%w[id full_name embedded embeddeds]) }
    specify { expect(model.new.attribute_names(false)).to eq(%w[id full_name])  }
  end

  describe '#attributes' do
    specify { expect(stub_model.new.attributes).to eq({})  }
    specify { expect(model.new(full_name: 'Name').attributes)
      .to match({'id' => instance_of(ActiveData::UUID), 'full_name' => 'Name', 'embedded' => nil, 'embeddeds' => nil})  }
    specify { expect(model.new(full_name: 'Name').attributes(false))
      .to match({'id' => instance_of(ActiveData::UUID), 'full_name' => 'Name'})  }
  end

  describe '#assign_attributes' do
    let(:attributes) { { id: 42, full_name: 'Name', missed: 'value' } }
    subject { model.new }

    specify { expect { subject.assign_attributes(attributes) }.not_to change { subject.id } }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.full_name }.to('Name') }
  end

  describe '#inspect' do
    specify { expect(stub_model.new.inspect).to match(/#<\[anonymous model\]:\d+:\d+ \(no attributes\)>/) }
    specify { expect(stub_model(:user).new.inspect).to match(/#<User:\d+ \(no attributes\)>/) }
    specify { expect(stub_model { attribute :count, type: Integer; attribute :object }.new.inspect).to match(/#<\[anonymous model\]:\d+:\d+ \(count: nil, object: nil\)>/) }
    specify { expect(stub_model(:user) { attribute :count, type: Integer; attribute :object }.new.inspect).to match(/#<User:\d+ \(count: nil, object: nil\)>/) }
  end

  context 'attributes' do
    let(:model) do
      stub_class do
        include ActiveData::Model::Attributes
        include ActiveData::Model::Associations
        attr_accessor :name

        attribute :id
        attribute :hello
        attribute :string, String, default_blank: true, default: ->(record){ record.name }
        attribute :count, Integer, default: 10
        attribute(:calc, Integer) { 2 + 3 }
        attribute :enum, Integer, enum: [1, 2, 3]
        attribute :enum_with_default, Integer, enum: [1, 2, 3], default: 2
        attribute :foo, Boolean, default: false

        def initialize name = nil
          @attributes = self.class.initialize_attributes
          @name = name
        end
      end
    end

    subject { model.new('world') }

    specify { expect(model.enum_values).to eq([1, 2, 3]) }
    its(:enum_values) { should == [1, 2, 3] }
    its(:string_default) { should == 'world' }
    its(:count_default) { should == 10 }
    its(:name) { should == 'world' }
    its(:hello) { should be_nil }
    its(:count) { should == 10 }
    its(:calc) { should == 5 }
    specify { expect { subject.hello = 'worlds' } .to change { subject.hello } .from(nil).to('worlds') }
    specify { expect { subject.count = 20 } .to change { subject.count } .from(10).to(20) }
    specify { expect { subject.calc = 15 } .to change { subject.calc } .from(5).to(15) }

    context 'enums' do
      specify { subject.enum = 3; expect(subject.enum).to eq(3) }
      specify { subject.enum = '3'; expect(subject.enum).to eq(3) }
      specify { subject.enum = 10; expect(subject.enum).to eq(nil) }
      specify { subject.enum = 'hello'; expect(subject.enum).to eq(nil) }
      specify { subject.enum_with_default = 3; expect(subject.enum_with_default).to eq(3) }
      specify { subject.enum_with_default = 10; expect(subject.enum_with_default).to eq(2) }
    end

    context 'attribute caching' do
      context do
        before do
          subject.hello
          expect(subject.send(:attributes_cache)).to receive(:fetch).with('hello').once
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

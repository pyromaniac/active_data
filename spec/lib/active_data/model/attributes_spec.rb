require 'spec_helper'

describe ActiveData::Model::Attributes do
  let(:model) do
    stub_model do
      include ActiveData::Model::Associations
      include ActiveData::Model::Localization

      attribute :id, Integer
      attribute :full_name, String
      alias_attribute :name, :full_name

      localized :t, String
      alias_attribute :title, :t

      embeds_one(:author) {}
      embeds_many(:projects) {}
    end
  end

  describe '.reflect_on_attribute' do
    specify { expect(model.reflect_on_attribute(:full_name).name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute('full_name').name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute(:name).name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute(:foobar)).to be_nil }
  end

  describe '.has_attribute?' do
    specify { expect(model.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.has_attribute?(:name)).to eq(true) }
    specify { expect(model.has_attribute?(:foobar)).to eq(false) }
  end

  describe '.attribute_names' do
    specify { expect(stub_model.attribute_names).to eq([]) }
    specify { expect(model.attribute_names).to eq(%w[id full_name t author projects]) }
    specify { expect(model.attribute_names(false)).to eq(%w[id full_name t]) }
  end

  describe '.inspect' do
    specify { expect(stub_model.inspect).to match(/#<Class:0x\w+>\(no attributes\)/) }
    specify { expect(stub_model(:user).inspect).to eq('User(no attributes)') }
    specify do
      expect(stub_model do
               include ActiveData::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.inspect).to match(/#<Class:0x\w+>\(\*count: Integer, object: Object\)/) end
    specify do
      expect(stub_model(:user) do
               include ActiveData::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.inspect).to match('User(*count: Integer, object: Object)') end
  end

  describe '#==' do
    let(:model) do
      stub_model do
        attribute :name, String
        attribute :count, Float, default: 0
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

  describe '#attribute' do
    let(:instance) { model.new }
    specify { expect(instance.attribute(:full_name).reflection.name).to eq('full_name') }
    specify { expect(instance.attribute('full_name').reflection.name).to eq('full_name') }
    specify { expect(instance.attribute(:name).reflection.name).to eq('full_name') }
    specify { expect(instance.attribute(:foobar)).to be_nil }

    specify { expect(instance.attribute('full_name')).to equal(instance.attribute(:name)) }
  end

  describe '#has_attribute?' do
    specify { expect(model.new.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.new.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.new.has_attribute?(:name)).to eq(true) }
    specify { expect(model.new.has_attribute?(:foobar)).to eq(false) }
  end

  describe '#attribute_names' do
    specify { expect(stub_model.new.attribute_names).to eq([]) }
    specify { expect(model.new.attribute_names).to eq(%w[id full_name t author projects]) }
    specify { expect(model.new.attribute_names(false)).to eq(%w[id full_name t]) }
  end

  describe '#attribute_present?' do
    specify { expect(model.new.attribute_present?(:name)).to be(false) }
    specify { expect(model.new(name: '').attribute_present?(:name)).to be(false) }
    specify { expect(model.new(name: 'Name').attribute_present?(:name)).to be(true) }
  end

  describe '#attributes' do
    specify { expect(stub_model.new.attributes).to eq({}) }
    specify do
      expect(model.new(name: 'Name').attributes)
        .to match('id' => nil, 'full_name' => 'Name', 't' => {}, 'author' => nil, 'projects' => nil)
    end
    specify do
      expect(model.new(name: 'Name').attributes(false))
        .to match('id' => nil, 'full_name' => 'Name', 't' => {})
    end
  end

  describe '#assign_attributes' do
    let(:attributes) { {id: 42, full_name: 'Name', missed: 'value'} }
    subject { model.new }

    specify { expect { subject.assign_attributes(attributes) }.to change { subject.id }.to(42) }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.full_name }.to('Name') }

    context 'features stack and assign order' do
      let(:model) do
        stub_model do
          attr_reader :logger

          def self.log(a)
            define_method("#{a}=") do |*args|
              log(a)
              super(*args)
            end
          end

          def log(o)
            (@logger ||= []).push(o)
          end

          attribute :plain1, String
          attribute :plain2, String
          log(:plain1)
          log(:plain2)
        end
      end
      subject { model.new }

      specify do
        expect { subject.assign_attributes(plain1: 'value', plain2: 'value') }
          .to change { subject.logger }.to(%i[plain1 plain2])
      end

      specify do
        expect { subject.assign_attributes(plain2: 'value', plain1: 'value') }
          .to change { subject.logger }.to(%i[plain2 plain1])
      end

      context do
        before do
          model.class_eval do
            include ActiveData::Model::Representation
            include ActiveData::Model::Associations

            embeds_one :assoc do
              attribute :assoc_plain, String
            end
            accepts_nested_attributes_for :assoc

            represents :assoc_plain, of: :assoc

            log(:assoc_attributes)
            log(:assoc_plain)

            def assign_attributes(attrs)
              super attrs.merge(attrs.extract!('plain2'))
            end
          end
        end

        specify do
          expect { subject.assign_attributes(assoc_plain: 'value', assoc_attributes: {}, plain1: 'value', plain2: 'value') }
            .to change { subject.logger }.to(%i[plain1 assoc_attributes assoc_plain plain2])
        end

        specify do
          expect { subject.assign_attributes(plain1: 'value', plain2: 'value', assoc_plain: 'value', assoc_attributes: {}) }
            .to change { subject.logger }.to(%i[plain1 assoc_attributes assoc_plain plain2])
        end
      end
    end
  end

  describe '#inspect' do
    specify { expect(stub_model.new.inspect).to match(/#<#<Class:0x\w+> \(no attributes\)>/) }
    specify { expect(stub_model(:user).new.inspect).to match(/#<User \(no attributes\)>/) }
    specify do
      expect(stub_model do
               include ActiveData::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.new(object: 'String').inspect).to match(/#<#<Class:0x\w+> \*count: nil, object: "String">/) end
    specify do
      expect(stub_model(:user) do
               include ActiveData::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.new.inspect).to match(/#<User \*count: nil, object: nil>/) end
  end

  context 'attributes integration' do
    let(:model) do
      stub_class do
        include ActiveData::Model::Attributes
        include ActiveData::Model::Associations
        attr_accessor :name

        attribute :id, Integer
        attribute :hello, Object
        attribute :string, String, default: ->(record) { record.name }
        attribute :count, Integer, default: '10'
        attribute(:calc, Integer) { 2 + 3 }
        attribute :enum, Integer, enum: [1, 2, 3]
        attribute :enum_with_default, Integer, enum: [1, 2, 3], default: '2'
        attribute :foo, Boolean, default: false
        collection :array, Integer, enum: [1, 2, 3], default: 7

        def initialize(name = nil)
          super()
          @name = name
        end
      end
    end

    subject { model.new('world') }

    its(:enum_values) { should == [1, 2, 3] }
    its(:string_default) { should == 'world' }
    its(:count_default) { should == '10' }
    its(:name) { should == 'world' }
    its(:hello) { should eq(nil) }
    its(:hello?) { should eq(false) }
    its(:count) { should == 10 }
    its(:count_before_type_cast) { should == '10' }
    its(:count_came_from_user?) { should eq(false) }
    its(:count?) { should eq(true) }
    its(:calc) { should == 5 }
    its(:enum?) { should eq(false) }
    its(:enum_with_default?) { should eq(true) }
    specify { expect { subject.hello = 'worlds' }.to change { subject.hello }.from(nil).to('worlds') }
    specify { expect { subject.count = 20 }.to change { subject.count }.from(10).to(20) }
    specify { expect { subject.calc = 15 }.to change { subject.calc }.from(5).to(15) }
    specify { expect { subject.count = '11' }.to change { subject.count_came_from_user? }.from(false).to(true) }

    context 'enums' do
      specify do
        subject.enum = 3
        expect(subject.enum).to eq(3)
      end
      specify do
        subject.enum = '3'
        expect(subject.enum).to eq(3)
      end
      specify do
        subject.enum = 10
        expect(subject.enum).to eq(nil)
      end
      specify do
        subject.enum = 'hello'
        expect(subject.enum).to eq(nil)
      end
      specify do
        subject.enum_with_default = 3
        expect(subject.enum_with_default).to eq(3)
      end
      specify do
        subject.enum_with_default = 10
        expect(subject.enum_with_default).to be_nil
      end
    end

    context 'array' do
      specify do
        subject.array = [2, 4]
        expect(subject.array).to eq([2, nil])
      end
      specify do
        subject.array = [2, 4]
        expect(subject.array?).to eq(true)
      end
      specify do
        subject.array = [2, 4]
        expect(subject.array_values).to eq([1, 2, 3])
      end
      specify do
        subject.array = [2, 4]
        expect(subject.array_default).to eq(7)
      end
    end

    context 'attribute caching' do
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
        attribute :foo, String
      end
    end

    let!(:descendant1) do
      Class.new ancestor do
        attribute :bar, String
      end
    end

    let!(:descendant2) do
      Class.new ancestor do
        attribute :baz, String
        attribute :moo, String
      end
    end

    specify { expect(ancestor._attributes.keys).to eq(['foo']) }
    specify { expect(ancestor.instance_methods).to include :foo, :foo= }
    specify { expect(ancestor.instance_methods).not_to include :bar, :bar=, :baz, :baz= }
    specify { expect(descendant1._attributes.keys).to eq(%w[foo bar]) }
    specify { expect(descendant1.instance_methods).to include :foo, :foo=, :bar, :bar= }
    specify { expect(descendant1.instance_methods).not_to include :baz, :baz= }
    specify { expect(descendant2._attributes.keys).to eq(%w[foo baz moo]) }
    specify { expect(descendant2.instance_methods).to include :foo, :foo=, :baz, :baz=, :moo, :moo= }
    specify { expect(descendant2.instance_methods).not_to include :bar, :bar= }
  end
end

require 'spec_helper'

describe ActiveData::Model::Validations::NestedValidator do
  before do
    stub_model(:validated_assoc) do
      include ActiveData::Model
      include ActiveData::Model::Lifecycle
      include ActiveData::Model::Primary

      primary :id, Integer
      attribute :name, String

      validates_presence_of :name
    end

    stub_model(:unvalidated_assoc) do
      include ActiveData::Model
      include ActiveData::Model::Lifecycle

      attribute :name, String
    end

    stub_model(:main) do
      include ActiveData::Model::Persistence
      include ActiveData::Model::Associations

      attribute :name, String

      validates_presence_of :name

      embeds_one :validated_one, class_name: 'ValidatedAssoc'
      embeds_one :unvalidated_one, class_name: 'UnvalidatedAssoc'
      embeds_many :validated_many, class_name: 'ValidatedAssoc'
      embeds_many :unvalidated_many, class_name: 'UnvalidatedAssoc'
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_one: {name: 'name'} }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_one: {} }
    it { is_expected.not_to be_valid }
    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to('validated_one.name': ["can't be blank"])
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_one: {name: 'name'} }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_one: {} }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{name: 'name'}] }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{}] }
    it { is_expected.not_to be_valid }
    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to('validated_many.0.name': ["can't be blank"])
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_many: [{name: 'name'}] }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_many: [{}] }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{name: 'name'}], validated_one: {} }
    it { is_expected.not_to be_valid }
    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to('validated_one.name': ["can't be blank"])
    end
  end

  context 'accepts nested attributes for one' do
    before { Main.accepts_nested_attributes_for :validated_one, allow_destroy: true }
    subject(:instance) { Main.instantiate name: 'hello', validated_one: {id: 1, name: 'name'} }

    specify do
      instance.validated_one_attributes = {id: 1, name: '', _destroy: true}
      is_expected.to be_valid
    end
  end

  context 'accepts nested attributes for many' do
    before { Main.accepts_nested_attributes_for :validated_many, allow_destroy: true }
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{id: 1, name: 'name'}] }

    specify do
      instance.validated_many_attributes = [{id: 1, name: '', _destroy: true}]
      is_expected.to be_valid
    end
  end

  context 'object field is invalid and referenced object does not include AutosaveAssociation' do
    before do
      stub_class(:validated_object) do
        include ActiveData::Model::Validations
        include ActiveData::Model::Attributes
        include ActiveData::Model::Primary

        primary :id
        attribute :title, String
        validates_presence_of :title
      end

      Main.class_eval do
        include ActiveData::Model::Associations
        attribute :object, Object
        validates :object, nested: true
      end
    end

    subject(:instance) { Main.instantiate name: 'hello', object: object, validated_one: {name: 'name'} }

    context do
      let(:object) { ValidatedObject.new(title: 'Mr.') }
      it { is_expected.to be_valid }
    end

    context do
      let(:object) { ValidatedObject.new }
      it do
        expect { subject.valid? }.not_to raise_error
        expect(subject).not_to be_valid
      end
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{}], validated_one: {name: 'name'} }
    it { is_expected.not_to be_valid }
    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to('validated_many.0.name': ["can't be blank"])
    end
  end

  describe '.validates_nested?' do
    specify { expect(Main).to be_validates_nested(:validated_one) }
    specify { expect(Main).to be_validates_nested(:unvalidated_one) }
    specify { expect(Main).not_to be_validates_nested(:something_else) }
  end
end

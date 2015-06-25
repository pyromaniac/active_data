require 'spec_helper'

describe ActiveData::Model::Validations::AssociatedValidator do
  let(:main) do
    stub_model(:main) do
      # def self.model_name
      #   ActiveModel::Name.new(self, nil, "Main")
      # end

      include ActiveData::Model::Persistence
      include ActiveData::Model::Associations

      attribute :name

      validates_presence_of :name
      validates_associated :validated_one, :unvalidated_one, :validated_many, :unvalidated_many

      embeds_one :validated_one, class_name: 'ValidatedAssoc'
      embeds_one :unvalidated_one, class_name: 'UnvalidatedAssoc'
      embeds_many :validated_many, class_name: 'ValidatedAssoc'
      embeds_many :unvalidated_many, class_name: 'UnvalidatedAssoc'
    end
  end

  class ValidatedAssoc
    include ActiveData::Model
    include ActiveData::Model::Lifecycle

    attribute :name

    validates_presence_of :name
  end

  class UnvalidatedAssoc
    include ActiveData::Model
    include ActiveData::Model::Lifecycle

    attribute :name
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_one: { name: 'name' } }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_one: { } }
    it { is_expected.not_to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_one: { name: 'name' } }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_one: { } }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ name: 'name' }] }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ }] }
    it { is_expected.not_to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_many: [{ name: 'name' }] }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_many: [{ }] }
    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ name: 'name' }], validated_one: { } }
    it { is_expected.not_to be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ }], validated_one: { name: 'name' } }
    it { is_expected.not_to be_valid }
  end
end

require 'spec_helper'

describe ActiveData::Validations do
  let(:main) do
    Class.new do
      def self.model_name
        ActiveModel::Name.new(self, nil, "Main")
      end

      include ActiveData::Model
      include ActiveData::Validations

      attribute :name

      validates_presence_of :name
      validates_associated :validated_one, :unvalidated_one, :validated_many, :unvalidated_many

      embeds_one :validated_one, class_name: ValidatedAssoc
      embeds_one :unvalidated_one, class_name: UnvalidatedAssoc
      embeds_many :validated_many, class_name: ValidatedAssoc
      embeds_many :unvalidated_many, class_name: UnvalidatedAssoc
    end
  end

  class ValidatedAssoc
    include ActiveData::Model

    attribute :name

    validates_presence_of :name
  end

  class UnvalidatedAssoc
    include ActiveData::Model

    attribute :name
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_one: { name: 'name' } }
    it { should be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_one: { } }
    it { should_not be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_one: { name: 'name' } }
    it { should be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_one: { } }
    it { should be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ name: 'name' }] }
    it { should be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ }] }
    it { should_not be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_many: [{ name: 'name' }] }
    it { should be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', unvalidated_many: [{ }] }
    it { should be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ name: 'name' }], validated_one: { } }
    it { should_not be_valid }
  end

  context do
    subject(:instance) { main.instantiate name: 'hello', validated_many: [{ }], validated_one: { name: 'name' } }
    it { should_not be_valid }
  end
end

require 'spec_helper'

describe ActiveData::Model::Attributes::Reflections::Collection do
  def reflection(options = {})
    described_class.new(:field, options)
  end

  describe '.build' do
    before { stub_class(:target) }
    specify do
      described_class.build(Target, :field)

      expect(Target).to be_method_defined(:field)
      expect(Target).to be_method_defined(:field=)
      expect(Target).to be_method_defined(:field?)
      expect(Target).to be_method_defined(:field_before_type_cast)
      expect(Target).to be_method_defined(:field_default)
      expect(Target).to be_method_defined(:field_values)
    end
  end

  describe '#alias_attribute' do
    before { stub_class(:target) }

    specify do
      described_class.build(Target, :field).alias_attribute(:field_alias, Target)

      expect(Target).to be_method_defined(:field_alias)
      expect(Target).to be_method_defined(:field_alias=)
      expect(Target).to be_method_defined(:field_alias?)
      expect(Target).to be_method_defined(:field_alias_before_type_cast)
      expect(Target).to be_method_defined(:field_alias_default)
      expect(Target).to be_method_defined(:field_alias_values)
    end
  end
end

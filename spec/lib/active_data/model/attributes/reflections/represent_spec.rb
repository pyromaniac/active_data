require 'spec_helper'

describe ActiveData::Model::Attributes::Reflections::Represent do
  def reflection(options = {})
    described_class.new(:field, options.reverse_merge(of: :subject))
  end

  describe '.build' do
    before { stub_class(:target) }

    specify do
      described_class.build(Target, :field, of: :subject)

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
      described_class.build(Target, :field, of: :subject).alias_attribute(:field_alias, Target)

      expect(Target).to be_method_defined(:field_alias)
      expect(Target).to be_method_defined(:field_alias=)
      expect(Target).to be_method_defined(:field_alias?)
      expect(Target).to be_method_defined(:field_alias_before_type_cast)
      expect(Target).to be_method_defined(:field_alias_default)
      expect(Target).to be_method_defined(:field_alias_values)
    end
  end

  describe '#type' do
    specify { expect(reflection.type).to eq(Object) }
    specify { expect(reflection(type: :whatever).type).to eq(Object) }
  end

  describe '#reference' do
    specify { expect { reflection(of: nil) }.to raise_error ArgumentError }
    specify { expect(reflection(of: :subject).reference).to eq('subject') }
  end

  describe '#attribute' do
    specify { expect(reflection.attribute).to eq('field') }
    specify { expect(reflection(attribute: 'hello').attribute).to eq('hello') }
  end

  describe '#reader' do
    specify { expect(reflection.reader).to eq('field') }
    specify { expect(reflection(attribute: 'hello').reader).to eq('hello') }
    specify { expect(reflection(reader: 'world').reader).to eq('world') }
  end

  describe '#reader_before_type_cast' do
    specify { expect(reflection.reader_before_type_cast).to eq('field_before_type_cast') }
    specify { expect(reflection(attribute: 'hello').reader_before_type_cast).to eq('hello_before_type_cast') }
    specify { expect(reflection(reader: 'world').reader_before_type_cast).to eq('world_before_type_cast') }
  end

  describe '#writer' do
    specify { expect(reflection.writer).to eq('field=') }
    specify { expect(reflection(attribute: 'hello').writer).to eq('hello=') }
    specify { expect(reflection(writer: 'world').writer).to eq('world=') }
  end
end

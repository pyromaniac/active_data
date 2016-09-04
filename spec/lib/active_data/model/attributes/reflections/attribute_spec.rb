require 'spec_helper'

describe ActiveData::Model::Attributes::Reflections::Attribute do
  def reflection(options = {})
    described_class.new(:field, options)
  end

  describe '.build' do
    before { stub_class(:target) }

    specify { expect(described_class.build(Class.new, Target, :field, String).type).to eq(String) }
    specify { expect(described_class.build(Class.new, Target, :field) {}.defaultizer).to be_a(Proc) }
    specify do
      described_class.build(Class.new, Target, :field)

      expect(Target).to be_method_defined(:field)
      expect(Target).to be_method_defined(:field=)
      expect(Target).to be_method_defined(:field?)
      expect(Target).to be_method_defined(:field_before_type_cast)
      expect(Target).to be_method_defined(:field_default)
      expect(Target).to be_method_defined(:field_values)
    end
  end

  describe '#generate_methods' do
    before { stub_class(:target) }

    specify do
      described_class.generate_methods(:field_alias, Target)

      expect(Target).to be_method_defined(:field_alias)
      expect(Target).to be_method_defined(:field_alias=)
      expect(Target).to be_method_defined(:field_alias?)
      expect(Target).to be_method_defined(:field_alias_before_type_cast)
      expect(Target).to be_method_defined(:field_alias_default)
      expect(Target).to be_method_defined(:field_alias_values)
    end
  end

  describe '#defaultizer' do
    specify { expect(reflection.defaultizer).to be_nil }
    specify { expect(reflection(default: 42).defaultizer).to eq(42) }
    specify { expect(reflection(default: -> {}).defaultizer).to be_a Proc }
  end

  describe '#typecaster' do
    before do
      stub_class(:dummy, String)
      stub_class(:dummy_dummy, Dummy)
    end

    specify { expect(reflection(type: Object).typecaster).to eq(ActiveData.typecaster(Object)) }
    specify { expect(reflection(type: String).typecaster).to eq(ActiveData.typecaster(String)) }
    specify { expect(reflection(type: Dummy).typecaster).to eq(ActiveData.typecaster(String)) }
    specify { expect(reflection(type: DummyDummy).typecaster).to eq(ActiveData.typecaster(String)) }
  end

  describe '#enumerizer' do
    specify { expect(reflection.enumerizer).to be_nil }
    specify { expect(reflection(enum: 42).enumerizer).to eq(42) }
    specify { expect(reflection(enum: -> {}).enumerizer).to be_a Proc }
    specify { expect(reflection(in: 42).enumerizer).to eq(42) }
    specify { expect(reflection(in: -> {}).enumerizer).to be_a Proc }
    specify { expect(reflection(enum: 42, in: -> {}).enumerizer).to eq(42) }
  end

  describe '#normalizers' do
    specify { expect(reflection.normalizers).to eq([]) }
    specify { expect(reflection(normalizer: -> {}).normalizers).to be_a Array }
    specify { expect(reflection(normalizer: -> {}).normalizers.first).to be_a Proc }
  end
end

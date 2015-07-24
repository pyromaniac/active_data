require 'spec_helper'

describe ActiveData::Model::Attributes::Reflections::Base do
  def reflection(options = {})
    described_class.new(:field, options)
  end

  describe '.build' do
    before { stub_class(:dummy, String) }

    specify { expect(described_class.build(Dummy, :field).name).to eq('field') }
    specify { expect(described_class.build(Dummy, :field, String).type).to eq(String) }
    specify { expect(described_class.build(Dummy, :field) {}.defaultizer).to be_a(Proc) }
  end

  describe '.attribute_class' do
    before do
      stub_class('SomeScope::Borogoves', described_class)
      stub_class('ActiveData::Model::Attributes::Borogoves')
    end

    specify { expect(described_class.attribute_class).to eq(ActiveData::Model::Attributes::Base) }
    specify { expect(SomeScope::Borogoves.attribute_class).to eq(ActiveData::Model::Attributes::Borogoves) }
  end

  describe '#name' do
    specify { expect(reflection.name).to eq('field') }
  end

  describe '#build_attribute' do
    before do
      stub_class('SomeScope::Borogoves', described_class)
      stub_class('ActiveData::Model::Attributes::Borogoves', ActiveData::Model::Attributes::Base)
      stub_class(:owner)
    end

    let(:reflection) { SomeScope::Borogoves.new(:field) }
    let(:owner) { Owner.new }

    specify { expect(reflection.build_attribute(owner)).to be_a(ActiveData::Model::Attributes::Borogoves) }
    specify { expect(reflection.build_attribute(owner).reflection).to eq(reflection) }
    specify { expect(reflection.build_attribute(owner).owner).to eq(owner) }
  end

  describe '#type' do
    before { stub_class(:dummy, String) }

    specify { expect(reflection.type).to eq(Object) }
    specify { expect(reflection(type: String).type).to eq(String) }
    specify { expect(reflection(type: :string).type).to eq(String) }
    specify { expect(reflection(type: Dummy).type).to eq(Dummy) }
    specify { expect { reflection(type: :blabla).type }.to raise_error NameError }
  end

  describe '#defaultizer' do
    specify { expect(reflection.defaultizer).to be_nil }
    specify { expect(reflection(default: 42).defaultizer).to eq(42) }
    specify { expect(reflection(default: ->{ }).defaultizer).to be_a Proc }
  end

  describe '#typecaster' do
    before do
      stub_class(:dummy, String)
      stub_class(:dummy_dummy, Dummy)
    end

    specify { expect(reflection.typecaster).to eq(ActiveData.typecaster(Object)) }
    specify { expect(reflection(type: String).typecaster).to eq(ActiveData.typecaster(String)) }
    specify { expect(reflection(type: Dummy).typecaster).to eq(ActiveData.typecaster(String)) }
    specify { expect(reflection(type: DummyDummy).typecaster).to eq(ActiveData.typecaster(String)) }
  end

  describe '#enumerizer' do
    specify { expect(reflection.enumerizer).to be_nil }
    specify { expect(reflection(enum: 42).enumerizer).to eq(42) }
    specify { expect(reflection(enum: ->{ }).enumerizer).to be_a Proc }
    specify { expect(reflection(in: 42).enumerizer).to eq(42) }
    specify { expect(reflection(in: ->{ }).enumerizer).to be_a Proc }
    specify { expect(reflection(enum: 42, in: ->{ }).enumerizer).to eq(42) }
  end

  describe '#normalizers' do
    specify { expect(reflection.normalizers).to eq([]) }
    specify { expect(reflection(normalizer: ->{}).normalizers).to be_a Array }
    specify { expect(reflection(normalizer: ->{}).normalizers.first).to be_a Proc }
  end
end

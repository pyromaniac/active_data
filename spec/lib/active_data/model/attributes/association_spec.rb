require 'spec_helper'

describe ActiveData::Model::Attributes::Association do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Association.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end

  describe '#read_value' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v ? v.strip : v }, default: :world, enum: ['hello', '42', 'world']) }
    let(:object) { Object.new }

    specify { expect(field.read_value(nil)).to eq(nil) }
    specify { expect(field.read_value('')).to eq('') }
    specify { expect(field.read_value(:world)).to eq(:world) }
    specify { expect(field.read_value(object)).to eq(object) }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v.strip }, default: :world, enum: ['hello', '42', 'world']) }
    let(:object) { Object.new }

    specify { expect(field.read_value_before_type_cast(nil)).to eq(nil) }
    specify { expect(field.read_value_before_type_cast('')).to eq('') }
    specify { expect(field.read_value_before_type_cast(:world)).to eq(:world) }
    specify { expect(field.read_value_before_type_cast(object)).to eq(object) }
  end
end

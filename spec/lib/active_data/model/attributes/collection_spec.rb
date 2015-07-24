# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Collection do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Collection.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end

  describe '#read_value' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v.uniq }, default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value(nil)).to eq([]) }
    specify { expect(field.read_value([nil])).to eq([nil]) }
    specify { expect(field.read_value('hello')).to eq(['hello']) }
    specify { expect(field.read_value([42])).to eq(['42']) }
    specify { expect(field.read_value([43])).to eq([nil]) }
    specify { expect(field.read_value([43, 44])).to eq([nil]) }
    specify { expect(field.read_value([''])).to eq([nil]) }
    specify { expect(field.read_value(['hello', 42])).to eq(['hello', '42']) }
    specify { expect(field.read_value(['hello', false])).to eq(['hello', nil]) }

    context do
      let(:field) { attribute(type: String, normalizer: ->(v){ v.uniq }, default: :world) }

      specify { expect(field.read_value(nil)).to eq([]) }
      specify { expect(field.read_value([nil, nil])).to eq(['world']) }
      specify { expect(field.read_value('hello')).to eq(['hello']) }
      specify { expect(field.read_value([42])).to eq(['42']) }
      specify { expect(field.read_value([''])).to eq(['']) }
    end
  end

  describe '#read_value_before_type_cast' do
    let(:field) { attribute(type: String, default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value_before_type_cast(nil)).to eq([]) }
    specify { expect(field.read_value_before_type_cast([nil])).to eq([:world]) }
    specify { expect(field.read_value_before_type_cast('hello')).to eq(['hello']) }
    specify { expect(field.read_value_before_type_cast([42])).to eq([42]) }
    specify { expect(field.read_value_before_type_cast([43])).to eq([43]) }
    specify { expect(field.read_value_before_type_cast([43, 44])).to eq([43, 44]) }
    specify { expect(field.read_value_before_type_cast([''])).to eq(['']) }
    specify { expect(field.read_value_before_type_cast(['hello', 42])).to eq(['hello', 42]) }
    specify { expect(field.read_value_before_type_cast(['hello', false])).to eq(['hello', false]) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.read_value_before_type_cast(nil)).to eq([]) }
      specify { expect(field.read_value_before_type_cast([nil, nil])).to eq([:world, :world]) }
      specify { expect(field.read_value_before_type_cast('hello')).to eq(['hello']) }
      specify { expect(field.read_value_before_type_cast([42])).to eq([42]) }
      specify { expect(field.read_value_before_type_cast([''])).to eq(['']) }
    end
  end
end

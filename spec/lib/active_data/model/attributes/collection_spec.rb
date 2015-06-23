# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Collection do
  def build_field(options = {}, &block)
    described_class.new(:field, options.reverse_merge(mode: :collection), &block)
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v.uniq.compact }, default: 'world', enum: ['hello', '42']) }

    specify { expect(field.read_value(nil, self)).to eq([]) }
    specify { expect(field.read_value([nil], self)).to eq(['world']) }
    specify { expect(field.read_value('hello', self)).to eq(['hello']) }
    specify { expect(field.read_value([42], self)).to eq(['42']) }
    specify { expect(field.read_value([43], self)).to eq(['world']) }
    specify { expect(field.read_value([''], self)).to eq(['world']) }
    specify { expect(field.read_value(['hello', 42], self)).to eq(['hello', '42']) }
    specify { expect(field.read_value(['hello', false], self)).to eq(['hello', 'world']) }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, default: 'world', enum: ['hello', '42']) }

    specify { expect(field.read_value_before_type_cast(nil, self)).to eq([]) }
    specify { expect(field.read_value_before_type_cast([nil], self)).to eq([nil]) }
    specify { expect(field.read_value_before_type_cast('hello', self)).to eq(['hello']) }
    specify { expect(field.read_value_before_type_cast([42], self)).to eq([42]) }
    specify { expect(field.read_value_before_type_cast([43], self)).to eq([43]) }
    specify { expect(field.read_value_before_type_cast([''], self)).to eq(['']) }
    specify { expect(field.read_value_before_type_cast(['hello', 42], self)).to eq(['hello', 42]) }
    specify { expect(field.read_value_before_type_cast(['hello', false], self)).to eq(['hello', false]) }
  end

  context 'integration' do
    let(:model) do
      stub_model do
        collection :values, Integer
      end
    end

    specify { expect(model.new(values: '42').values).to eq([42]) }
  end
end

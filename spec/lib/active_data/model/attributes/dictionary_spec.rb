# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Dictionary do
  def build_field(options = {}, &block)
    described_class.new(:field, options.reverse_merge(mode: :dictionary), &block)
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v.delete_if { |_, v| v == nil } },
      default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value(nil, self)).to eq({}) }
    specify { expect(field.read_value({}, self)).to eq({}) }
    specify { expect(field.read_value({a: nil}, self)).to eq({}) }
    specify { expect(field.read_value({a: ''}, self)).to eq({}) }
    specify { expect(field.read_value({a: 1}, self)).to eq({}) }
    specify { expect(field.read_value({a: 42}, self)).to eq({'a' => '42'}) }
    specify { expect(field.read_value({a: 'hello', b: '42'}, self)).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(field.read_value({a: 'hello', b: '1'}, self)).to eq({'a' => 'hello'}) }
    specify { expect(field.read_value({a: 'hello', x: '42'}, self)).to eq({'a' => 'hello', 'x' => '42'}) }

    context do
      let(:field) { build_field(type: String, normalizer: ->(v){ v.delete_if { |_, v| v == nil } },
        default: :world) }

      specify { expect(field.read_value(nil, self)).to eq({}) }
      specify { expect(field.read_value({}, self)).to eq({}) }
      specify { expect(field.read_value({a: 1}, self)).to eq({'a' => '1'}) }
      specify { expect(field.read_value({a: nil, b: nil}, self)).to eq({'a' => 'world', 'b' => 'world'}) }
      specify { expect(field.read_value({a: ''}, self)).to eq({'a' => ''}) }
    end

    context 'with :keys' do
      let(:field) { build_field(type: String, keys: ['a', :b]) }

      specify { expect(field.read_value(nil, self)).to eq({}) }
      specify { expect(field.read_value({}, self)).to eq({}) }
      specify { expect(field.read_value({a: 1, 'b' => 2, c: 3, 'd' => 4}, self)).to eq({'a' => '1', 'b' => '2'}) }
    end
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value_before_type_cast(nil, self)).to eq({}) }
    specify { expect(field.read_value_before_type_cast({}, self)).to eq({}) }
    specify { expect(field.read_value_before_type_cast({a: 1}, self)).to eq({'a' => 1}) }
    specify { expect(field.read_value_before_type_cast({a: nil}, self)).to eq({'a' => :world}) }
    specify { expect(field.read_value_before_type_cast({a: ''}, self)).to eq({'a' => ''}) }
    specify { expect(field.read_value_before_type_cast({a: 42}, self)).to eq({'a' => 42}) }
    specify { expect(field.read_value_before_type_cast({a: 'hello', b: '42'}, self)).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(field.read_value_before_type_cast({a: 'hello', b: '1'}, self)).to eq({'a' => 'hello', 'b' => '1'}) }
    specify { expect(field.read_value_before_type_cast({a: 'hello', x: '42'}, self)).to eq({'a' => 'hello', 'x' => '42'}) }

    context do
      let(:field) { build_field(type: String, default: :world) }

      specify { expect(field.read_value_before_type_cast(nil, self)).to eq({}) }
      specify { expect(field.read_value_before_type_cast({}, self)).to eq({}) }
      specify { expect(field.read_value_before_type_cast({a: 1}, self)).to eq({'a' => 1}) }
      specify { expect(field.read_value_before_type_cast({a: nil, b: nil}, self)).to eq({'a' => :world, 'b' => :world}) }
      specify { expect(field.read_value_before_type_cast({a: ''}, self)).to eq({'a' => ''}) }
    end
  end

  context 'integration' do
    let(:model) do
      stub_model do
        dictionary :values, Integer
      end
    end

    specify { expect(model.new(values: {a: '42'}).values).to eq({'a' => 42}) }
  end
end

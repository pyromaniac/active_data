# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Dictionary do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Dictionary.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end

  describe '#read_value' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v.delete_if { |_, v| v == nil } },
      default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value(nil)).to eq({}) }
    specify { expect(field.read_value({})).to eq({}) }
    specify { expect(field.read_value({a: nil})).to eq({}) }
    specify { expect(field.read_value({a: ''})).to eq({}) }
    specify { expect(field.read_value({a: 1})).to eq({}) }
    specify { expect(field.read_value({a: 42})).to eq({'a' => '42'}) }
    specify { expect(field.read_value({a: 'hello', b: '42'})).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(field.read_value({a: 'hello', b: '1'})).to eq({'a' => 'hello'}) }
    specify { expect(field.read_value({a: 'hello', x: '42'})).to eq({'a' => 'hello', 'x' => '42'}) }

    context do
      let(:field) { attribute(type: String, normalizer: ->(v){ v.delete_if { |_, v| v == nil } },
        default: :world) }

      specify { expect(field.read_value(nil)).to eq({}) }
      specify { expect(field.read_value({})).to eq({}) }
      specify { expect(field.read_value({a: 1})).to eq({'a' => '1'}) }
      specify { expect(field.read_value({a: nil, b: nil})).to eq({'a' => 'world', 'b' => 'world'}) }
      specify { expect(field.read_value({a: ''})).to eq({'a' => ''}) }
    end

    context 'with :keys' do
      let(:field) { attribute(type: String, keys: ['a', :b]) }

      specify { expect(field.read_value(nil)).to eq({}) }
      specify { expect(field.read_value({})).to eq({}) }
      specify { expect(field.read_value({a: 1, 'b' => 2, c: 3, 'd' => 4})).to eq({'a' => '1', 'b' => '2'}) }
      specify { expect(field.read_value({a: 1, c: 3, 'd' => 4})).to eq({'a' => '1'}) }
    end
  end

  describe '#read_value_before_type_cast' do
    let(:field) { attribute(type: String, default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value_before_type_cast(nil)).to eq({}) }
    specify { expect(field.read_value_before_type_cast({})).to eq({}) }
    specify { expect(field.read_value_before_type_cast({a: 1})).to eq({'a' => 1}) }
    specify { expect(field.read_value_before_type_cast({a: nil})).to eq({'a' => :world}) }
    specify { expect(field.read_value_before_type_cast({a: ''})).to eq({'a' => ''}) }
    specify { expect(field.read_value_before_type_cast({a: 42})).to eq({'a' => 42}) }
    specify { expect(field.read_value_before_type_cast({a: 'hello', b: '42'})).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(field.read_value_before_type_cast({a: 'hello', b: '1'})).to eq({'a' => 'hello', 'b' => '1'}) }
    specify { expect(field.read_value_before_type_cast({a: 'hello', x: '42'})).to eq({'a' => 'hello', 'x' => '42'}) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.read_value_before_type_cast(nil)).to eq({}) }
      specify { expect(field.read_value_before_type_cast({})).to eq({}) }
      specify { expect(field.read_value_before_type_cast({a: 1})).to eq({'a' => 1}) }
      specify { expect(field.read_value_before_type_cast({a: nil, b: nil})).to eq({'a' => :world, 'b' => :world}) }
      specify { expect(field.read_value_before_type_cast({a: ''})).to eq({'a' => ''}) }
    end

    context 'with :keys' do
      let(:field) { attribute(type: String, keys: ['a', :b]) }

      specify { expect(field.read_value_before_type_cast(nil)).to eq({}) }
      specify { expect(field.read_value_before_type_cast({})).to eq({}) }
      specify { expect(field.read_value_before_type_cast({a: 1, 'b' => 2, c: 3, 'd' => 4}))
        .to eq({'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}) }
    end
  end
end

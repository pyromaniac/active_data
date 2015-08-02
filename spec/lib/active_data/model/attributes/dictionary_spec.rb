# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Dictionary do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Dictionary.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end

  describe '#read' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v.delete_if { |_, v| v == nil } },
      default: :world, enum: ['hello', '42']) }

    specify { expect(field.tap { |r| r.write(nil) }.read).to eq({}) }
    specify { expect(field.tap { |r| r.write({}) }.read).to eq({}) }
    specify { expect(field.tap { |r| r.write({a: nil}) }.read).to eq({}) }
    specify { expect(field.tap { |r| r.write({a: ''}) }.read).to eq({}) }
    specify { expect(field.tap { |r| r.write({a: 1}) }.read).to eq({}) }
    specify { expect(field.tap { |r| r.write({a: 42}) }.read).to eq({'a' => '42'}) }
    specify { expect(field.tap { |r| r.write({a: 'hello', b: '42'}) }.read).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(field.tap { |r| r.write({a: 'hello', b: '1'}) }.read).to eq({'a' => 'hello'}) }
    specify { expect(field.tap { |r| r.write({a: 'hello', x: '42'}) }.read).to eq({'a' => 'hello', 'x' => '42'}) }

    context do
      let(:field) { attribute(type: String, normalizer: ->(v){ v.delete_if { |_, v| v == nil } },
        default: :world) }

      specify { expect(field.tap { |r| r.write(nil) }.read).to eq({}) }
      specify { expect(field.tap { |r| r.write({}) }.read).to eq({}) }
      specify { expect(field.tap { |r| r.write({a: 1}) }.read).to eq({'a' => '1'}) }
      specify { expect(field.tap { |r| r.write({a: nil, b: nil}) }.read).to eq({'a' => 'world', 'b' => 'world'}) }
      specify { expect(field.tap { |r| r.write({a: ''}) }.read).to eq({'a' => ''}) }
    end

    context 'with :keys' do
      let(:field) { attribute(type: String, keys: ['a', :b]) }

      specify { expect(field.tap { |r| r.write(nil) }.read).to eq({}) }
      specify { expect(field.tap { |r| r.write({}) }.read).to eq({}) }
      specify { expect(field.tap { |r| r.write({a: 1, 'b' => 2, c: 3, 'd' => 4}) }.read).to eq({'a' => '1', 'b' => '2'}) }
      specify { expect(field.tap { |r| r.write({a: 1, c: 3, 'd' => 4}) }.read).to eq({'a' => '1'}) }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, default: :world, enum: ['hello', '42']) }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq({}) }
    specify { expect(field.tap { |r| r.write({}) }.read_before_type_cast).to eq({}) }
    specify { expect(field.tap { |r| r.write({a: 1}) }.read_before_type_cast).to eq({'a' => 1}) }
    specify { expect(field.tap { |r| r.write({a: nil}) }.read_before_type_cast).to eq({'a' => :world}) }
    specify { expect(field.tap { |r| r.write({a: ''}) }.read_before_type_cast).to eq({'a' => ''}) }
    specify { expect(field.tap { |r| r.write({a: 42}) }.read_before_type_cast).to eq({'a' => 42}) }
    specify { expect(field.tap { |r| r.write({a: 'hello', b: '42'}) }.read_before_type_cast).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(field.tap { |r| r.write({a: 'hello', b: '1'}) }.read_before_type_cast).to eq({'a' => 'hello', 'b' => '1'}) }
    specify { expect(field.tap { |r| r.write({a: 'hello', x: '42'}) }.read_before_type_cast).to eq({'a' => 'hello', 'x' => '42'}) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq({}) }
      specify { expect(field.tap { |r| r.write({}) }.read_before_type_cast).to eq({}) }
      specify { expect(field.tap { |r| r.write({a: 1}) }.read_before_type_cast).to eq({'a' => 1}) }
      specify { expect(field.tap { |r| r.write({a: nil, b: nil}) }.read_before_type_cast).to eq({'a' => :world, 'b' => :world}) }
      specify { expect(field.tap { |r| r.write({a: ''}) }.read_before_type_cast).to eq({'a' => ''}) }
    end

    context 'with :keys' do
      let(:field) { attribute(type: String, keys: ['a', :b]) }

      specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq({}) }
      specify { expect(field.tap { |r| r.write({}) }.read_before_type_cast).to eq({}) }
      specify { expect(field.tap { |r| r.write({a: 1, 'b' => 2, c: 3, 'd' => 4}) }.read_before_type_cast)
        .to eq({'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}) }
    end
  end

  context 'integration' do
    before do
      stub_model(:post) do
        dictionary :options, type: String
      end
    end

    specify { expect(Post.new(options: {a: 'hello', b: 42}).options).to eq({'a' => 'hello', 'b' => '42'}) }
    specify { expect(Post.new(options: {a: 'hello', b: 42}).options_before_type_cast).to eq({'a' => 'hello', 'b' => 42}) }
    specify { expect(Post.new.options?).to eq(false) }
    specify { expect(Post.new(options: {a: 'hello', b: 42}).options?).to eq(true) }
  end
end

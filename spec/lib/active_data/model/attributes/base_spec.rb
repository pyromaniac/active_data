# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Base do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Base.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end

  describe '#read' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v ? v.strip : v }, default: :world, enum: ['hello', '42', 'world']) }
    let(:object) { Object.new }

    specify { expect(field.tap { |r| r.write(nil) }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write('') }.read).to eq('') }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq(:world) }
    specify { expect(field.tap { |r| r.write(object) }.read).to eq(object) }
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v.strip }, default: :world, enum: ['hello', '42', 'world']) }
    let(:object) { Object.new }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq(nil) }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(object) }.read_before_type_cast).to eq(object) }
  end

  describe '#value_present?' do
    let(:field) { attribute }

    specify { expect(field.tap { |r| r.write(true) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(false) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(nil) }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write('') }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write(:world) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(Object.new) }).to be_value_present }
    specify { expect(field.tap { |r| r.write([]) }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write([42]) }).to be_value_present }
    specify { expect(field.tap { |r| r.write({}) }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write({hello: 42}) }).to be_value_present }
  end
end

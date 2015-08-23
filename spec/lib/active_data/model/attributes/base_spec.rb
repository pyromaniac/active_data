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

    specify { expect(field.tap { |r| r.write(nil) }.read).to be_nil }
    specify { expect(field.tap { |r| r.write('') }.read).to eq('') }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq(:world) }
    specify { expect(field.tap { |r| r.write(object) }.read).to eq(object) }

    context ':readonly' do
      specify { expect(attribute(readonly: true).tap { |r| r.write('string') }.read).to be_nil }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, normalizer: ->(v){ v.strip }, default: :world, enum: ['hello', '42', 'world']) }
    let(:object) { Object.new }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to be_nil }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(object) }.read_before_type_cast).to eq(object) }

    context ':readonly' do
      specify { expect(attribute(readonly: true).tap { |r| r.write('string') }.read_before_type_cast).to be_nil }
    end
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

  describe '#readonly?' do
    specify { expect(attribute).not_to be_readonly }
    specify { expect(attribute(readonly: false)).not_to be_readonly }
    specify { expect(attribute(readonly: true)).to be_readonly }
    specify { expect(attribute(readonly: -> { false })).not_to be_readonly }
    specify { expect(attribute(readonly: -> { true })).to be_readonly }
  end
end

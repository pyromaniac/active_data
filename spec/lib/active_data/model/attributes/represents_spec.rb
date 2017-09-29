require 'spec_helper'

describe ActiveData::Model::Attributes::Represents do
  before { stub_model(:dummy) }

  def attribute(*args)
    options = args.extract_options!
    Dummy.add_attribute(ActiveData::Model::Attributes::Reflections::Represents, :full_name, options.reverse_merge(of: :subject))
    Dummy.new.attribute(:full_name)
  end

  before do
    stub_model :subject do
      attribute :full_name, String
    end
  end

  describe '#new' do
    before { attribute(:full_name) }
    let(:attributes) { {foo: 'bar'} }

    specify { expect { Dummy.new(attributes) }.to_not change { attributes } }
  end

  describe '#write' do
    subject { Subject.new }
    before { allow_any_instance_of(Dummy).to receive_messages(value: 42, subject: subject) }
    let(:field) { attribute }

    specify { expect { field.write('hello') }.to change { subject.full_name }.to('hello') }
  end

  describe '#read' do
    subject { Subject.new(full_name: :hello) }
    before { allow_any_instance_of(Dummy).to receive_messages(value: 42, subject: subject) }
    let(:field) { attribute(normalizer: ->(v) { v && v.is_a?(String) ? v.strip : v }, default: :world, enum: ['hello', '42', 'world', :world]) }

    specify { expect(field.read).to eq('hello') }
    specify { expect(field.tap { |r| r.write(nil) }.read).to eq(:world) }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq('world') }
    specify { expect(field.tap { |r| r.write('hello') }.read).to eq('hello') }
    specify { expect(field.tap { |r| r.write(' hello ') }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write(42) }.read).to eq('42') }
    specify { expect(field.tap { |r| r.write(43) }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write('') }.read).to eq(nil) }

    specify { expect { subject.full_name = 42 }.to change { field.read }.to('42') }

    context ':readonly' do
      specify { expect(attribute(readonly: true).tap { |r| r.write('string') }.read).to eq('hello') }
    end

    context do
      subject { Subject.new }
      let(:field) { attribute(default: -> { Time.now.to_f }) }
      specify { expect { sleep(0.01) }.not_to change { field.read } }
    end
  end

  describe '#read_before_type_cast' do
    subject { Subject.new(full_name: :hello) }
    before { allow_any_instance_of(Dummy).to receive_messages(value: 42, subject: subject) }
    let(:field) { attribute(normalizer: ->(v) { v.strip }, default: :world, enum: %w[hello 42 world]) }

    specify { expect(field.read_before_type_cast).to eq(:hello) }
    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write('hello') }.read_before_type_cast).to eq('hello') }
    specify { expect(field.tap { |r| r.write(42) }.read_before_type_cast).to eq(42) }
    specify { expect(field.tap { |r| r.write(43) }.read_before_type_cast).to eq(43) }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }

    specify { expect { subject.full_name = 42 }.to change { field.read_before_type_cast }.to(42) }

    context ':readonly' do
      specify { expect(attribute(readonly: true).tap { |r| r.write('string') }.read_before_type_cast).to eq(:hello) }
    end

    context do
      subject { Subject.new }
      let(:field) { attribute(default: -> { Time.now.to_f }) }
      specify { expect { sleep(0.01) }.not_to change { field.read_before_type_cast } }
    end
  end
end

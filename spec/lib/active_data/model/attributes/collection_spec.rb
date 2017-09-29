require 'spec_helper'

describe ActiveData::Model::Attributes::Collection do
  before { stub_model(:dummy) }

  def attribute(*args)
    options = args.extract_options!
    Dummy.add_attribute(ActiveData::Model::Attributes::Reflections::Collection, :field, options)
    Dummy.new.attribute(:field)
  end

  describe '#read' do
    let(:field) { attribute(type: String, normalizer: ->(v) { v.uniq }, default: :world, enum: %w[hello 42]) }

    specify { expect(field.tap { |r| r.write(nil) }.read).to eq([]) }
    specify { expect(field.tap { |r| r.write([nil]) }.read).to eq([nil]) }
    specify { expect(field.tap { |r| r.write('hello') }.read).to eq(['hello']) }
    specify { expect(field.tap { |r| r.write([42]) }.read).to eq(['42']) }
    specify { expect(field.tap { |r| r.write([43]) }.read).to eq([nil]) }
    specify { expect(field.tap { |r| r.write([43, 44]) }.read).to eq([nil]) }
    specify { expect(field.tap { |r| r.write(['']) }.read).to eq([nil]) }
    specify { expect(field.tap { |r| r.write(['hello', 42]) }.read).to eq(%w[hello 42]) }
    specify { expect(field.tap { |r| r.write(['hello', false]) }.read).to eq(['hello', nil]) }

    context do
      let(:field) { attribute(type: String, normalizer: ->(v) { v.uniq }, default: :world) }

      specify { expect(field.tap { |r| r.write(nil) }.read).to eq([]) }
      specify { expect(field.tap { |r| r.write([nil, nil]) }.read).to eq(['world']) }
      specify { expect(field.tap { |r| r.write('hello') }.read).to eq(['hello']) }
      specify { expect(field.tap { |r| r.write([42]) }.read).to eq(['42']) }
      specify { expect(field.tap { |r| r.write(['']) }.read).to eq(['']) }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, default: :world, enum: %w[hello 42]) }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq([]) }
    specify { expect(field.tap { |r| r.write([nil]) }.read_before_type_cast).to eq([:world]) }
    specify { expect(field.tap { |r| r.write('hello') }.read_before_type_cast).to eq(['hello']) }
    specify { expect(field.tap { |r| r.write([42]) }.read_before_type_cast).to eq([42]) }
    specify { expect(field.tap { |r| r.write([43]) }.read_before_type_cast).to eq([43]) }
    specify { expect(field.tap { |r| r.write([43, 44]) }.read_before_type_cast).to eq([43, 44]) }
    specify { expect(field.tap { |r| r.write(['']) }.read_before_type_cast).to eq(['']) }
    specify { expect(field.tap { |r| r.write(['hello', 42]) }.read_before_type_cast).to eq(['hello', 42]) }
    specify { expect(field.tap { |r| r.write(['hello', false]) }.read_before_type_cast).to eq(['hello', false]) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq([]) }
      specify { expect(field.tap { |r| r.write([nil, nil]) }.read_before_type_cast).to eq(%i[world world]) }
      specify { expect(field.tap { |r| r.write('hello') }.read_before_type_cast).to eq(['hello']) }
      specify { expect(field.tap { |r| r.write([42]) }.read_before_type_cast).to eq([42]) }
      specify { expect(field.tap { |r| r.write(['']) }.read_before_type_cast).to eq(['']) }
    end
  end

  context 'integration' do
    before do
      stub_model(:post) do
        collection :tags, String
      end
    end

    specify { expect(Post.new(tags: ['hello', 42]).tags).to eq(%w[hello 42]) }
    specify { expect(Post.new(tags: ['hello', 42]).tags_before_type_cast).to eq(['hello', 42]) }
    specify { expect(Post.new.tags?).to eq(false) }
    specify { expect(Post.new(tags: ['hello', 42]).tags?).to eq(true) }
  end
end

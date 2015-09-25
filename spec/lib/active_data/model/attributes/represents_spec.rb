# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Represents do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Represents.new(:full_name, options.reverse_merge(of: :subject))
    described_class.new(args.first || Object.new, reflection)
  end

  before do
    stub_model :subject do
      attribute :full_name, String
    end
  end

  describe '#write' do
    subject { Subject.new }
    let(:owner) { double(value: 42, subject: subject) }
    let(:field) { attribute(owner) }

    specify { expect { field.write('hello') }.to change { subject.full_name }.to('hello') }
  end

  describe '#read' do
    let(:owner) { double(value: 42, subject: Subject.new(full_name: :hello)) }
    let(:field) { attribute(owner, normalizer: ->(v){ v && v.is_a?(String) ? v.strip : v }, default: :world, enum: ['hello', '42', 'world', :world]) }

    specify { expect(field.read).to eq('hello') }
    specify { expect(field.tap { |r| r.write(nil) }.read).to eq(:world) }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq('world') }
    specify { expect(field.tap { |r| r.write('hello') }.read).to eq('hello') }
    specify { expect(field.tap { |r| r.write(' hello ') }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write(42) }.read).to eq('42') }
    specify { expect(field.tap { |r| r.write(43) }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write('') }.read).to eq(nil) }

    context ':readonly' do
      specify { expect(attribute(owner, readonly: true).tap { |r| r.write('string') }.read).to eq('hello') }
    end
  end

  describe '#read_before_type_cast' do
    let(:owner) { double(value: 42, subject: Subject.new(full_name: :hello)) }
    let(:field) { attribute(owner, normalizer: ->(v){ v.strip }, default: :world, enum: ['hello', '42', 'world']) }

    specify { expect(field.read_before_type_cast).to eq(:hello) }
    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write('hello') }.read_before_type_cast).to eq('hello') }
    specify { expect(field.tap { |r| r.write(42) }.read_before_type_cast).to eq(42) }
    specify { expect(field.tap { |r| r.write(43) }.read_before_type_cast).to eq(43) }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }

    context ':readonly' do
      specify { expect(attribute(owner, readonly: true).tap { |r| r.write('string') }.read_before_type_cast).to eq(:hello) }
    end
  end

  context 'integration' do
    before do
      stub_model(:author) do
        attribute :rate, Integer
      end

      stub_model(:post) do
        attribute :author
        alias_attribute :a, :author
        represents :rate, of: :a
        alias_attribute :r, :rate
      end
    end
    let(:author) { Author.new(rate: '42') }

    specify { expect(Post.reflect_on_attribute(:rate).reference).to eq('author') }

    specify { expect(Post.new(author: author).rate).to eq(42) }
    specify { expect(Post.new(author: author).rate_before_type_cast).to eq('42') }
    specify { expect(Post.new(rate: '33', author: author).rate).to eq(33) }
    specify { expect(Post.new(rate: '33', author: author).author.rate).to eq(33) }
    specify { expect(Post.new(r: '33', author: author).rate).to eq(33) }
    specify { expect(Post.new(r: '33', author: author).author.rate).to eq(33) }
    specify { expect(Post.new(author: author).rate?).to eq(true) }
    specify { expect(Post.new(rate: nil, author: author).rate?).to eq(false) }

    specify { expect(Post.new.rate).to be_nil }
    specify { expect(Post.new.rate_before_type_cast).to be_nil }
    specify { expect { Post.new(rate: '33') }.to raise_error(NoMethodError) }

    context do
      before do
        stub_class(:author, ActiveRecord::Base)

        stub_model(:post) do
          include ActiveData::Model::Associations

          references_one :author
          alias_association :a, :author
          represents :name, of: :a
        end
      end
      let!(:author) { Author.create!(name: 42) }

      specify { expect(Post.reflect_on_attribute(:name).reference).to eq('author') }

      specify { expect(Post.new(name: '33', author: author).name).to eq('33') }
      specify { expect(Post.new(name: '33', author: author).author.name).to eq('33') }
    end

    context 'multiple attributes in a single represents definition' do
      before do
        stub_model(:author) do
          attribute :first_name
          attribute :last_name
        end

        stub_model(:post) do
          attribute :author
          represents :first_name, :last_name, of: :author
        end
      end

      let(:author) { Author.new(first_name: 'John', last_name: 'Doe') }
      let(:post) { Post.new }

      specify do
        expect { post.update(author: author) }
          .to change { post.first_name }.to('John')
          .and change { post.last_name }.to('Doe')
      end
    end
  end
end

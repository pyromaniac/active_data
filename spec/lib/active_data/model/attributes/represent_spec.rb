# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Represent do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Represent.new(:full_name, options.reverse_merge(of: :subject))
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
  end

  context 'integration' do
    before do
      stub_model(:author) do
        attribute :rate, Integer
      end

      stub_model(:post) do
        attribute :author
        represent :rate, of: :author
      end
    end
    let(:author) { Author.new(rate: '42') }

    specify { expect(Post.new(author: author).rate).to eq(42) }
    specify { expect(Post.new(author: author).rate_before_type_cast).to eq('42') }
    specify { expect(Post.new(author: author, rate: '33').rate).to eq(33) }
    specify { expect(Post.new(author: author, rate: '33').author.rate).to eq(33) }
    specify { expect(Post.new(author: author).rate?).to eq(true) }
    specify { expect(Post.new(author: author, rate: nil).rate?).to eq(false) }

    specify { expect(Post.new.rate).to be_nil }
    specify { expect(Post.new.rate_before_type_cast).to be_nil }
    specify { expect(Post.new(rate: '33').rate).to eq('33') }
    specify { expect(Post.new(rate: '33').rate_before_type_cast).to eq('33') }

    context do
      let(:post) { Post.new(rate: '33') }

      specify { expect { post.update(author: author) }.to change { post.rate }.to 33 }
      specify { expect { post.update(author: author) }.not_to change { post.rate_before_type_cast } }

      specify { expect { post.update(author: author) }.to change { post.author.try(:rate) }.to 33 }
      specify { expect { post.update(author: author) }.to change { post.author.try(:rate_before_type_cast) }.to '33' }

      specify { expect { post.update(author: author) }.to change { author.rate }.to 33 }
      specify { expect { post.update(author: author) }.to change { author.rate_before_type_cast }.to '33' }
    end

    context do
      before do
        stub_class(:author, ActiveRecord::Base)

        stub_model(:post) do
          include ActiveData::Model::Associations

          references_one :author
          represent :name, of: :author
        end
      end
      let!(:author) { Author.create!(name: 42) }

      context do
        let(:post) { Post.new(name: 33) }

        specify { expect { post.update(author: author) }.to change { post.name }.to '33' }
        specify { expect { post.update(author: author) }.not_to change { post.name_before_type_cast } }

        specify { expect { post.update(author: author) }.to change { post.author.try(:name) }.to '33' }
        specify { expect { post.update(author: author) }.to change { post.author.try(:name_before_type_cast) }.to 33 }

        specify { expect { post.update(author: author) }.to change { author.name }.to '33' }
        specify { expect { post.update(author: author) }.to change { author.name_before_type_cast }.to 33 }

        specify { expect { post.update(author_id: author.id) }.to change { post.author.try(:name) }.to '33' }
        specify { expect { post.update(author_id: author.id) }.to change { post.author.try(:name_before_type_cast) }.to 33 }
      end
    end
  end
end

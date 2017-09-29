require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::EmbedsOne do
  before do
    stub_model(:author) do
      include ActiveData::Model::Lifecycle
      attribute :name, String
    end

    stub_model(:book) do
      include ActiveData::Model::Associations

      attribute :title, String
      embeds_one :author
    end
  end
  let(:book) { Book.new }

  specify { expect(book.author).to be_nil }

  context ':read, :write' do
    before do
      stub_model(:book) do
        include ActiveData::Model::Persistence
        include ActiveData::Model::Associations

        attribute :title
        embeds_one :author,
          read: lambda { |reflection, object|
            value = object.read_attribute(reflection.name)
            JSON.parse(value) if value.present?
          },
          write: lambda { |reflection, object, value|
            object.write_attribute(reflection.name, value ? value.to_json : nil)
          }
      end
    end

    let(:book) { Book.instantiate author: {name: 'Duke'}.to_json }
    let(:author) { Author.new(name: 'Rick') }

    specify do
      expect { book.author = author }
        .to change { book.read_attribute(:author) }
        .from({name: 'Duke'}.to_json).to({name: 'Rick'}.to_json)
    end
  end

  describe '#author=' do
    let(:author) { Author.new name: 'Author' }
    specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
    specify { expect { book.author = 'string' }.to raise_error ActiveData::AssociationTypeMismatch }

    context do
      let(:other) { Author.new name: 'Other' }
      before { book.author = other }
      specify { expect { book.author = author }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author = nil }.to change { book.author }.from(other).to(nil) }
    end
  end

  describe '#build_author' do
    let(:author) { Author.new name: 'Author' }
    specify { expect(book.build_author(name: 'Author')).to eq(author) }
    specify { expect { book.build_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
  end

  describe '#create_author' do
    let(:author) { Author.new name: 'Author' }
    specify { expect(book.create_author(name: 'Author')).to eq(author) }
    specify { expect { book.create_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
  end

  describe '#create_author!' do
    let(:author) { Author.new name: 'Author' }
    specify { expect(book.create_author!(name: 'Author')).to eq(author) }
    specify { expect { book.create_author!(name: 'Author') }.to change { book.author }.from(nil).to(author) }
  end

  context 'on the fly' do
    context do
      before do
        stub_model(:book) do
          include ActiveData::Model::Associations

          attribute :title, String
          embeds_one :author do
            attribute :name, String
          end
        end
      end

      specify { expect(Book.reflect_on_association(:author).klass).to eq(Book::Author) }
      specify { expect(Book.new.author).to be_nil }
      specify { expect(Book.new.tap { |b| b.create_author(name: 'Author') }.author).to be_a(Book::Author) }
      specify { expect(Book.new.tap { |b| b.create_author(name: 'Author') }.read_attribute(:author)).to eq('name' => 'Author') }
    end

    context do
      before do
        stub_model(:book) do
          include ActiveData::Model::Associations

          attribute :title, String
          embeds_one :author, class_name: 'Author' do
            attribute :age, Integer
          end
        end
      end

      specify { expect(Book.reflect_on_association(:author).klass).to eq(Book::Author) }
      specify { expect(Book.new.author).to be_nil }
      specify { expect(Book.new.tap { |b| b.create_author(name: 'Author') }.author).to be_a(Book::Author) }
      specify { expect(Book.new.tap { |b| b.create_author(name: 'Author') }.read_attribute(:author)).to eq('name' => 'Author', 'age' => nil) }
    end
  end
end

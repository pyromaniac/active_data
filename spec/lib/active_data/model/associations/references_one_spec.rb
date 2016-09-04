# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::ReferencesOne do
  before do
    stub_class(:author, ActiveRecord::Base) {}

    stub_model(:book) do
      include ActiveData::Model::Persistence
      include ActiveData::Model::Associations

      attribute :title, String
      references_one :author
    end
  end

  let(:author) { Author.create!(name: 'Johny') }
  let(:other) { Author.create!(name: 'Other') }
  let(:book) { Book.new }
  let(:association) { book.association(:author) }

  let(:existing_book) { Book.instantiate title: 'My Life', author_id: author.id }
  let(:existing_association) { existing_book.association(:author) }

  describe 'book#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(book.association(:author)) }
  end

  describe 'book#inspect' do
    specify { expect(existing_book.inspect).to eq('#<Book author: #<ReferencesOne #<Author id: 1, name: "Johny">>, title: "My Life", author_id: 1>') }
  end

  describe '#target' do
    specify { expect(association.target).to be_nil }
    specify { expect(existing_association.target).to eq(existing_book.author) }
  end

  describe '#loaded?' do
    let(:new_author) { Author.create(name: 'Morty') }

    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace(new_author) }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace(nil) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace(new_author) }.to change { existing_association.loaded? }.to(true) }
    specify { expect { existing_association.replace(nil) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { expect(association.reload).to be_nil }

    specify { expect(existing_association.reload).to be_a Author }
    specify { expect(existing_association.reload).to be_persisted }

    context do
      before { existing_association.reader.name = "New" }
      specify { expect { existing_association.reload }
        .to change { existing_association.reader.name }
        .from('New').to('Johny') }
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to be_nil }

    specify { expect(existing_association.reader).to be_a Author }
    specify { expect(existing_association.reader).to be_persisted }
  end

  describe '#default' do
    before { Book.references_one :author, default: ->(_book) { author.id } }
    let(:existing_book) { Book.instantiate title: 'My Life' }

    specify { expect(association.target).to eq(author) }
    specify { expect { association.replace(other) }.to change { association.target }.to(other) }
    specify { expect { association.replace(nil) }.to change { association.target }.to be_nil }

    specify { expect(existing_association.target).to be_nil }
    specify { expect { existing_association.replace(other) }.to change { existing_association.target }.to(other) }
    specify { expect { existing_association.replace(nil) }.not_to change { existing_association.target } }
  end


  describe '#writer' do
    context 'new owner' do
      let(:new_author) { Author.new(name: 'Morty') }

      let(:book) do
        Book.new.tap do |book|
          book.send(:mark_persisted!)
        end
      end

      specify { expect { association.writer(nil) }
        .not_to change { book.author_id } }
      specify { expect { association.writer(new_author) }
        .to change { association.reader.name rescue nil }.from(nil).to('Morty') }
      specify { expect { association.writer(new_author) }
        .not_to change { book.author_id }.from(nil) }

    end

    context 'persisted owner' do
      let(:new_author) { Author.create(name: 'Morty') }

      specify { expect { association.writer(stub_model(:dummy).new) }
        .to raise_error ActiveData::AssociationTypeMismatch }

      specify { expect(association.writer(nil)).to be_nil }
      specify { expect(association.writer(new_author)).to eq(new_author) }
      specify { expect { association.writer(nil) }
        .not_to change { book.read_attribute(:author_id) } }
      specify { expect { association.writer(new_author) }
        .to change { association.reader.try(:attributes) }.from(nil).to('id' => 1, 'name' => 'Morty') }
      specify { expect { association.writer(new_author) }
        .to change { book.read_attribute(:author_id) } }


      specify { expect { existing_association.writer(stub_class(:dummy, ActiveRecord::Base).new) rescue nil }
        .not_to change { existing_book.read_attribute(:author_id) } }
      specify { expect { existing_association.writer(stub_class(:dummy, ActiveRecord::Base).new) rescue nil }
        .not_to change { existing_association.reader } }

      specify { expect(existing_association.writer(nil)).to be_nil }
      specify { expect(existing_association.writer(new_author)).to eq(new_author) }
      specify { expect { existing_association.writer(nil) }
        .to change { existing_book.read_attribute(:author_id) }.from(author.id).to(nil) }
      specify { expect { existing_association.writer(new_author) }
        .to change { existing_association.reader.try(:attributes) }
        .from('id' => 1, 'name' => 'Johny').to('id' => 2, 'name' => 'Morty') }
      specify { expect { existing_association.writer(new_author) }
        .to change { existing_book.read_attribute(:author_id) }
        .from(author.id).to(new_author.id) }

    end
  end
end

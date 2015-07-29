# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::ReferencesMany do
  before do
    stub_model(:dummy)
    stub_class(:author, ActiveRecord::Base) do
      scope :name_starts_with_a, -> { where('name LIKE "a%"') }
    end

    stub_model(:book) do
      include ActiveData::Model::Persistence
      include ActiveData::Model::Associations

      attribute :title
      references_many :authors
    end
  end

  let(:author) { Author.create!(name: 'Rick') }
  let(:other) { Author.create!(name: 'Ben') }

  let(:book) { Book.new }
  let(:association) { book.association(:authors) }

  let(:existing_book) { Book.instantiate title: 'Genesis', author_ids: [author.id] }
  let(:existing_association) { existing_book.association(:authors) }

  describe 'book#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(book.association(:authors)) }
  end

  describe '#scope' do
    specify { expect(association.scope).to be_a ActiveRecord::Relation }
    specify { expect(association.scope).to respond_to(:where) }
    specify { expect(association.scope).to respond_to(:name_starts_with_a) }
  end

  describe '#target' do
    specify { expect(association.target).to eq([]) }
    specify { expect(existing_association.target).to eq(existing_book.authors) }
    specify { expect { association.concat author }.to change { association.target.count }.to(1) }
  end

  describe '#default' do
    before { Book.references_many :authors, default: ->(book) { author.id } }
    let(:existing_book) { Book.instantiate title: 'Genesis' }

    specify { expect(association.target).to eq([author]) }
    specify { expect { association.replace([other]) }.to change { association.target }.to([other]) }
    specify { expect { association.replace([]) }.to change { association.target }.to eq([]) }

    specify { expect(existing_association.target).to eq([]) }
    specify { expect { existing_association.replace([other]) }.to change { existing_association.target }.to([other]) }
    specify { expect { existing_association.replace([]) }.not_to change { existing_association.target } }
  end

  describe '#loaded?' do
    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace([]) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace([]) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { expect(association.reload).to eq([]) }

    specify { expect(existing_association.reload).to eq(existing_book.authors) }

    context do
      before { existing_association.reader.last.name = 'Conan' }
      specify { expect { existing_association.reload }
        .to change { existing_association.reader.map(&:name) }
        .from(['Conan']).to(['Rick']) }
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to eq([]) }
    specify { expect(association.reader).to be_a ActiveData::Model::Associations::ReferencedCollectionProxy }

    specify { expect(existing_association.reader.first).to be_a Author }
    specify { expect(existing_association.reader.first).to be_persisted }

    context do
      before { association.concat author }
      specify { expect(association.reader.last).to be_a Author }
      specify { expect(association.reader.size).to eq(1) }
      specify { expect(association.reader(true)).to eq([author]) }
    end

    context do
      before { existing_association.concat other }
      specify { expect(existing_association.reader.size).to eq(2) }
      specify { expect(existing_association.reader.last.name).to eq('Ben') }
      specify { expect(existing_association.reader(true).size).to eq(2) }
      specify { expect(existing_association.reader(true).last.name).to eq('Ben') }
    end

    context 'proxy missing method delection' do
      specify { expect(existing_association.reader).to respond_to(:where) }
      specify { expect(existing_association.reader).to respond_to(:name_starts_with_a) }
    end
  end

  describe '#writer' do
    let(:new_author1) { Author.create!(name: 'John') }
    let(:new_author2) { Author.create!(name: 'Adam') }

    specify { expect { association.writer([Dummy.new]) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { association.writer([Author.new]) }
      .to raise_error ActiveData::AssociationObjectNotPersisted }
    specify { expect { existing_association.writer([Author.new]) rescue nil }
      .not_to change { existing_association.target } }

    specify { expect { association.writer(nil) }.to raise_error NoMethodError }
    specify { expect { association.writer(new_author1) }.to raise_error NoMethodError }
    specify { expect(association.writer([])).to eq([]) }

    specify { expect(association.writer([new_author1])).to eq([new_author1]) }
    specify { expect { association.writer([new_author1]) }
      .to change { association.reader.map(&:name) }.from([]).to(['John']) }
    specify { expect { association.writer([new_author1]) }
      .to change { book.read_attribute(:author_ids) }
      .from([]).to([new_author1.id]) }

    specify { expect { existing_association.writer([new_author1, Dummy.new, new_author2]) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { existing_association.writer([new_author1, Dummy.new, new_author2]) rescue nil }
      .not_to change { existing_book.read_attribute(:author_ids) } }
    specify { expect { existing_association.writer([new_author1, Dummy.new, new_author2]) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect { existing_association.writer(nil) }.to raise_error NoMethodError }
    specify { expect { existing_association.writer(nil) rescue nil }
      .not_to change { existing_book.read_attribute(:author_ids) } }
    specify { expect { existing_association.writer(nil) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect(existing_association.writer([])).to eq([]) }
    specify { expect { existing_association.writer([]) }
      .to change { existing_book.read_attribute(:author_ids) }.to([]) }
    specify { expect { existing_association.writer([]) }
      .to change { existing_association.reader }.from([author]).to([]) }

    specify { expect(existing_association.writer([new_author1, new_author2])).to eq([new_author1, new_author2]) }
    specify { expect { existing_association.writer([new_author1, new_author2]) }
      .to change { existing_association.reader.map(&:name) }
      .from(['Rick']).to(['John', 'Adam']) }
    specify { expect { existing_association.writer([new_author1, new_author2]) }
      .to change { existing_book.read_attribute(:author_ids) }
      .from([author.id]).to([new_author1.id, new_author2.id]) }
  end

  describe '#concat' do
    let(:new_author1) { Author.create!(name: 'John') }
    let(:new_author2) { Author.create!(name: 'Adam') }

    specify { expect { association.concat(Dummy.new) }
      .to raise_error ActiveData::AssociationTypeMismatch }

    specify { expect { association.concat(nil) }.to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect(association.concat([])).to eq([]) }
    specify { expect(existing_association.concat([])).to eq(existing_book.authors) }
    specify { expect(existing_association.concat).to eq(existing_book.authors) }

    specify { expect(association.concat(new_author1)).to eq([new_author1]) }
    specify { expect { association.concat(new_author1) }
      .to change { association.reader.map(&:name) }.from([]).to(['John']) }
    specify { expect { association.concat(new_author1) }
      .to change { book.read_attribute(:author_ids) }.from([]).to([1]) }

    specify { expect { existing_association.concat(new_author1, Dummy.new, new_author2) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { existing_association.concat(new_author1, Dummy.new, new_author2) rescue nil }
      .to change { existing_book.read_attribute(:author_ids) }
      .from([author.id]).to([author.id, new_author1.id]) }
    specify { expect { existing_association.concat(new_author1, Dummy.new, new_author2) rescue nil }
      .to change { existing_association.reader.map(&:name) }
      .from(['Rick']).to(['Rick', 'John']) }

    specify { expect(existing_association.concat(new_author1, new_author2))
      .to eq([author, new_author1, new_author2]) }
    specify { expect { existing_association.concat([new_author1, new_author2]) }
      .to change { existing_association.reader.map(&:name) }
      .from(['Rick']).to(['Rick', 'John', 'Adam']) }
    specify { expect { existing_association.concat([new_author1, new_author2]) }
      .to change { existing_book.read_attribute(:author_ids) }
      .from([author.id]).to([author.id, new_author1.id, new_author2.id]) }
  end
end

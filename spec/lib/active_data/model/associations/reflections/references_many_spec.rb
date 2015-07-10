# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::ReferencesMany do
  before do
    stub_class(:author, ActiveRecord::Base)

    stub_model(:book) do
      include ActiveData::Model::Associations

      attribute :title
      references_many :authors
    end
  end

  let(:author) { Author.create!(name: 'Rick') }
  let(:other) { Author.create!(name: 'John') }
  let(:book) { Book.new }
  let(:book_with_author) { Book.new(authors: [author]) }

  specify { expect(book.authors).to be_empty }

  context ':class_name' do
    before do
      stub_model(:book) do
        include ActiveData::Model::Associations

        attribute :title
        references_many :creators, class_name: 'Author'
      end
    end

    let(:book) { Book.new }

    specify { expect { book.creators << author }
      .to change { book.creators }.from([]).to([author]) }
    specify { expect { book.creators << author }
      .to change { book.creator_ids }.from([]).to([author.id]) }
  end

  describe '#author' do
    it { expect(book.authors).not_to respond_to(:build) }
    it { expect(book.authors).not_to respond_to(:create) }
    it { expect(book.authors).not_to respond_to(:create!) }

    describe '#clear' do
      it { expect { book_with_author.authors.clear }.to change { book_with_author.authors }.from([author]).to([]) }
    end

    describe '#reload' do
      before { book.authors << author.tap { |a| a.name = 'Don Juan' } }
      it { expect { book.authors.reload }.to change { book.authors.map(&:name) }.from(['Don Juan']).to(['Rick']) }
    end

    describe '#concat' do
      it { expect { book.authors.concat author }.to change { book.authors }.from([]).to([author]) }
      it { expect { book.authors << author << other }.to change { book.authors }.from([]).to([author, other]) }
      context 'no duplication' do
        before { book.authors << author }
        it { expect { book.authors.concat author }.not_to change { book.authors }.from([author]) }
      end
    end
  end

  describe '#author_ids' do
    it { expect(book_with_author.author_ids).to eq([author.id]) }
    it { expect { book_with_author.author_ids << other.id }.to change { book_with_author.authors }.from([author]).to([author, other]) }
    it { expect { book_with_author.author_ids = [other.id] }.to change { book_with_author.authors }.from([author]).to([other]) }
  end

  describe '#authors=' do
    specify { expect { book.authors = [author] }.to change { book.authors }.from([]).to([author]) }
    specify { expect { book.authors = ['string'] }.to raise_error ActiveData::AssociationTypeMismatch }

    context do
      before { book.authors = [other] }
      specify { expect { book.authors = [author] }.to change { book.authors }.from([other]).to([author]) }
      specify { expect { book.authors = [author] }.to change { book.author_ids }.from([other.id]).to([author.id]) }
      specify { expect { book.authors = [] }.to change { book.authors }.from([other]).to([]) }
      specify { expect { book.authors = [] }.to change { book.author_ids }.from([other.id]).to([]) }
    end

    context 'model not persisted' do
      let(:author) { Author.new }
      specify { expect { book.authors = [author] }.to raise_error ActiveData::AssociationObjectNotPersisted }
    end
  end

  describe '#author_ids=' do
    specify { expect { book.author_ids = [author.id] }.to change { book.author_ids }.from([]).to([author.id]) }
    specify { expect { book.author_ids = [author.id] }.to change { book.authors }.from([]).to([author]) }

    context do
      before { book.authors = [other] }
      specify { expect { book.author_ids = [author.id] }.to change { book.author_ids }.from([other.id]).to([author.id]) }
      specify { expect { book.author_ids = [author.id] }.to change { book.authors }.from([other]).to([author]) }
      specify { expect { book.author_ids = [] }.to change { book.author_ids }.from([other.id]).to([]) }
      specify { expect { book.author_ids = [] }.to change { book.authors }.from([other]).to([]) }
    end
  end
end

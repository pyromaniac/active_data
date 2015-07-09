# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::ReferencesOne do
  before do
    stub_class(:author, ActiveRecord::Base)

    stub_model(:book) do
      include ActiveData::Model::Associations

      attribute :title
      references_many :authors
    end
  end
  let(:book) { Book.new }

  specify { expect(book.authors).to be_empty }

  context ':class_name' do
    before do
      stub_model(:book) do
        include ActiveData::Model::Associations

        attribute :title
        references_many :creators, class_name: 'Author'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }
    let(:book) { Book.new }

    specify { expect { book.creators << author }
      .to change { book.creators }.from([]).to([author]) }
    specify { expect { book.creators << author }
      .to change { book.creator_ids }.from([]).to([author.id]) }
  end

  describe '#author' do
    it { expect { book.authors.build(name: 'Rick') }.to raise_error ActiveData::OperationNotSupported }
    it { expect { book.authors.create(name: 'Rick') }.to raise_error ActiveData::OperationNotSupported }
    it { expect { book.authors.create!(name: 'Rick') }.to raise_error ActiveData::OperationNotSupported }

    describe '#reload' do
      before { book.authors << author }
      it { expect { book.authors.reload }.to change { book.authors }.from([author]).to([]) }
    end

    describe '#concat' do
      it { expect { book.authors.concat author }.to change { book.authors }.from([]).to([author]) }
      context 'no duplication' do
        before { book.authors << author}
        it { expect { book.authors.concat author }.not_to change { book.authors }.from([author]) }
      end
    end
  end

  describe '#author=' do
    let(:author) { Author.create! name: 'Author' }
    specify { expect { book.authors = [author] }.to change { book.authors }.from([]).to([author]) }
    specify { expect { book.authors = ['string'] }.to raise_error ActiveData::AssociationTypeMismatch }

    context do
      let(:other) { Author.create! name: 'Other' }
      before { book.author = other }
      specify { expect { book.author = author }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author = author }.to change { book.author_id }.from(other.id).to(author.id) }
      specify { expect { book.author = nil }.to change { book.author }.from(other).to(nil) }
      specify { expect { book.author = nil }.to change { book.author_id }.from(other.id).to(nil) }
    end

    context 'model not persisted' do
      let(:author) { Author.new }
      specify { expect { book.author = author }.to raise_error ActiveData::AssociationObjectNotPersisted }
    end
  end

  describe '#author_id=' do
    let(:author) { Author.create!(name: 'Author') }
    specify { expect { book.author_id = author.id }.to change { book.author_id }.from(nil).to(author.id) }
    specify { expect { book.author_id = author.id }.to change { book.author }.from(nil).to(author) }

    context do
      let(:other) { Author.create!(name: 'Other') }
      before { book.author = other }
      specify { expect { book.author_id = author.id }.to change { book.author_id }.from(other.id).to(author.id) }
      specify { expect { book.author_id = author.id }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author_id = nil }.to change { book.author_id }.from(other.id).to(nil) }
      specify { expect { book.author_id = nil }.to change { book.author }.from(other).to(nil) }
    end
  end
end

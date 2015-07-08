# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::ReferencesOne do
  before do
    stub_class(:author, ActiveRecord::Base)

    stub_model(:book) do
      include ActiveData::Model::Associations

      attribute :title
      references_one :author
    end
  end
  let(:book) { Book.new }

  specify { expect(book.author).to be_nil }

  context ':class_name' do
    before do
      stub_model(:book) do
        include ActiveData::Model::Associations

        attribute :title
        references_one :creator, class_name: 'Author'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }
    let(:book) { Book.new }

    specify { expect { book.creator = author }
      .to change { book.creator }.from(nil).to(author) }
    specify { expect { book.creator = author }
      .to change { book.creator_id }.from(nil).to(author.id) }
  end

  describe '#author=' do
    let(:author) { Author.create! name: 'Author' }
    specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
    specify { expect { book.author = 'string' }.to raise_error ActiveData::AssociationTypeMismatch }

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

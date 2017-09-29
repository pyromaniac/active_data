require 'spec_helper'

describe ActiveData::Model::Associations::ReferencesOne do
  before do
    stub_class(:author, ActiveRecord::Base) do
      validates :name, presence: true
    end

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

  describe '#build' do
    specify { expect(association.build).to be_a Author }
    specify { expect(association.build).not_to be_persisted }

    specify do
      expect { association.build(name: 'Morty') }
        .not_to change { book.author_id }
    end
    specify do
      expect { association.build(name: 'Morty') }
        .to change { book.author }.from(nil)
        .to(an_instance_of(Author).and(have_attributes(name: 'Morty')))
    end

    specify do
      expect { existing_association.build(name: 'Morty') }
        .to change { existing_book.author_id }
        .from(author.id).to(nil)
    end
    specify do
      expect { existing_association.build(name: 'Morty') }
        .to change { existing_book.author }.from(author)
        .to(an_instance_of(Author).and(have_attributes(name: 'Morty')))
    end

    context 'dirty' do
      before do
        Book.include ActiveData::Model::Dirty
      end

      specify do
        expect { existing_association.build(name: 'Morty') }
          .to change { existing_book.changes }
          .from({}).to('author_id' => [author.id, nil])
      end
    end
  end

  describe '#create' do
    specify { expect(association.create).to be_a Author }
    specify { expect(association.create).not_to be_persisted }

    specify { expect(association.create(name: 'Fred')).to be_a Author }
    specify { expect(association.create(name: 'Fred')).to be_persisted }

    specify do
      expect { association.create }
        .not_to change { book.author_id }
    end
    specify do
      expect { association.create(name: 'Fred') }
        .to change { book.author_id }
        .from(nil).to(be_a(Integer))
    end

    specify do
      expect { existing_association.create }
        .to change { existing_book.author_id }
        .from(author.id).to(nil)
    end
    specify do
      expect { existing_association.create(name: 'Fred') }
        .to change { existing_book.author_id }
        .from(author.id).to(be_a(Integer))
    end

    context 'dirty' do
      before do
        Book.include ActiveData::Model::Dirty
      end

      specify do
        expect { existing_association.create(name: 'Fred') }
          .to change { existing_book.changes }
          .from({}).to('author_id' => [author.id, be_a(Integer)])
      end
    end
  end

  describe '#create!' do
    specify { expect { association.create! }.to raise_error ActiveRecord::RecordInvalid }
    specify do
      expect { muffle(ActiveRecord::RecordInvalid) { association.create! } }
        .to change { association.target }
        .from(nil).to(an_instance_of(Author))
    end

    specify { expect(association.create!(name: 'Fred')).to be_a Author }
    specify { expect(association.create!(name: 'Fred')).to be_persisted }

    specify do
      expect { muffle(ActiveRecord::RecordInvalid) { association.create! } }
        .not_to change { book.author_id }
    end
    specify do
      expect { muffle(ActiveRecord::RecordInvalid) { association.create! } }
        .to change { association.reader.try(:attributes).try(:slice, 'name') }
        .from(nil).to('name' => nil)
    end
    specify do
      expect { association.create(name: 'Fred') }
        .to change { book.author_id }
        .from(nil).to(be_a(Integer))
    end

    specify do
      expect { muffle(ActiveRecord::RecordInvalid) { existing_association.create! } }
        .to change { existing_book.author_id }
        .from(author.id).to(nil)
    end
    specify do
      expect { muffle(ActiveRecord::RecordInvalid) { existing_association.create! } }
        .to change { existing_association.reader.try(:attributes).try(:slice, 'name') }
        .from('name' => 'Johny').to('name' => nil)
    end
    specify do
      expect { existing_association.create!(name: 'Fred') }
        .to change { existing_book.author_id }
        .from(author.id).to(be_a(Integer))
    end
  end

  context do
    shared_examples 'apply_changes' do |method|
      specify do
        association.build(name: 'Fred')
        expect(association.send(method)).to eq(true)
      end
      specify do
        association.build(name: 'Fred')
        expect { association.send(method) }
          .to change { association.target.persisted? }.to(true)
      end
      specify do
        association.build(name: 'Fred')
        expect { association.send(method) }
          .to change { book.author_id }
          .from(nil).to(be_a(Integer))
      end
      specify do
        existing_association.target.name = 'Fred'
        expect { existing_association.send(method) }
          .not_to change { author.reload.name }
      end
      specify do
        existing_association.target.mark_for_destruction
        expect { existing_association.send(method) }
          .not_to change { existing_association.target.destroyed? }
      end
      specify do
        existing_association.target.mark_for_destruction
        expect { existing_association.send(method) }
          .not_to change { existing_book.author_id }
      end
      specify do
        existing_association.target.destroy!
        expect { existing_association.send(method) }
          .not_to change { existing_association.target.destroyed? }
      end
      specify do
        existing_association.target.destroy!
        expect { existing_association.send(method) }
          .not_to change { existing_book.author_id }
      end

      context ':autosave' do
        before do
          Book.references_one :author, autosave: true
        end

        specify do
          association.build(name: 'Fred')
          expect(association.send(method)).to eq(true)
        end
        specify do
          association.build(name: 'Fred')
          expect { association.send(method) }
            .to change { association.target.persisted? }.to(true)
        end
        specify do
          existing_association.target.name = 'Fred'
          expect { existing_association.send(method) }
            .to change { author.reload.name }.from('Johny').to('Fred')
        end
        specify do
          existing_association.target.mark_for_destruction
          expect { existing_association.send(method) }
            .to change { existing_association.target.destroyed? }
            .from(false).to(true)
        end
        specify do
          existing_association.target.mark_for_destruction
          expect { existing_association.send(method) }
            .not_to change { existing_book.author_id }
            .from(author.id)
        end
        specify do
          existing_association.target.destroy!
          expect { existing_association.send(method) }
            .not_to change { existing_association.target.destroyed? }
            .from(true)
        end
        specify do
          existing_association.target.destroy!
          expect { existing_association.send(method) }
            .not_to change { existing_book.author_id }
            .from(author.id)
        end
      end
    end

    describe '#apply_changes' do
      include_examples 'apply_changes', :apply_changes

      specify do
        association.build
        expect(association.apply_changes).to eq(false)
      end
      specify do
        association.build
        expect { association.apply_changes }
          .not_to change { association.target.persisted? }.from(false)
      end

      context ':autosave' do
        before do
          Book.references_one :author, autosave: true
        end

        specify do
          association.build
          expect(association.apply_changes).to eq(false)
        end
        specify do
          association.build
          expect { association.apply_changes }
            .not_to change { association.target.persisted? }.from(false)
        end
      end
    end

    describe '#apply_changes!' do
      include_examples 'apply_changes', :apply_changes!

      specify do
        association.build
        expect { association.apply_changes! }
          .to raise_error(ActiveData::AssociationChangesNotApplied)
      end
      specify do
        association.build
        expect { muffle(ActiveData::AssociationChangesNotApplied) { association.apply_changes! } }
          .not_to change { association.target.persisted? }.from(false)
      end

      context ':autosave' do
        before do
          Book.references_one :author, autosave: true
        end

        specify do
          association.build
          expect { association.apply_changes! }
            .to raise_error(ActiveData::AssociationChangesNotApplied)
        end
        specify do
          association.build
          expect { muffle(ActiveData::AssociationChangesNotApplied) { association.apply_changes! } }
            .not_to change { association.target.persisted? }.from(false)
        end
      end
    end
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
      before { existing_association.reader.name = 'New' }
      specify do
        expect { existing_association.reload }
          .to change { existing_association.reader.name }
          .from('New').to('Johny')
      end
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

      specify do
        expect { association.writer(nil) }
          .not_to change { book.author_id }
      end
      specify do
        expect { association.writer(new_author) }
          .to change { muffle(NoMethodError) { association.reader.name } }
          .from(nil).to('Morty')
      end
      specify do
        expect { association.writer(new_author) }
          .not_to change { book.author_id }.from(nil)
      end
    end

    context 'persisted owner' do
      let(:new_author) { Author.create(name: 'Morty') }

      specify do
        expect { association.writer(stub_model(:dummy).new) }
          .to raise_error ActiveData::AssociationTypeMismatch
      end

      specify { expect(association.writer(nil)).to be_nil }
      specify { expect(association.writer(new_author)).to eq(new_author) }
      specify do
        expect { association.writer(nil) }
          .not_to change { book.read_attribute(:author_id) }
      end
      specify do
        expect { association.writer(new_author) }
          .to change { association.reader.try(:attributes) }.from(nil).to('id' => 1, 'name' => 'Morty')
      end
      specify do
        expect { association.writer(new_author) }
          .to change { book.read_attribute(:author_id) }
      end

      context do
        before do
          stub_class(:dummy, ActiveRecord::Base) do
            self.table_name = :authors
          end
        end

        specify do
          expect { muffle(ActiveData::AssociationTypeMismatch) { existing_association.writer(Dummy.new) } }
            .not_to change { existing_book.read_attribute(:author_id) }
        end
        specify do
          expect { muffle(ActiveData::AssociationTypeMismatch) { existing_association.writer(Dummy.new) } }
            .not_to change { existing_association.reader }
        end
      end

      specify { expect(existing_association.writer(nil)).to be_nil }
      specify { expect(existing_association.writer(new_author)).to eq(new_author) }
      specify do
        expect { existing_association.writer(nil) }
          .to change { existing_book.read_attribute(:author_id) }
          .from(author.id).to(nil)
      end
      specify do
        expect { existing_association.writer(new_author) }
          .to change { existing_association.reader.try(:attributes) }
          .from('id' => 1, 'name' => 'Johny').to('id' => 2, 'name' => 'Morty')
      end
      specify do
        expect { existing_association.writer(new_author) }
          .to change { existing_book.read_attribute(:author_id) }
          .from(author.id).to(new_author.id)
      end
    end
  end
end

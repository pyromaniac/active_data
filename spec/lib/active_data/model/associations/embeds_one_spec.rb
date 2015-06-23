# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsOne do
  before do
    stub_model(:author) do
      include ActiveData::Model::Lifecycle

      attribute :name
      validates :name, presence: true
    end

    stub_model(:book) do
      include ActiveData::Model::Persistence
      include ActiveData::Model::Associations

      attribute :title
      embeds_one :author
    end
  end

  let(:book) { Book.new }
  let(:association) { book.association(:author) }

  let(:existing_book) { Book.instantiate title: 'My Life', author: {'name' => 'Johny'} }
  let(:existing_association) { existing_book.association(:author) }

  describe 'book#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(book.association(:author)) }
  end

  describe '#build' do
    specify { expect(association.build).to be_a Author }
    specify { expect(association.build).not_to be_persisted }

    specify { expect { association.build(name: 'Fred') }
      .not_to change { book.read_attribute(:author) } }

    specify { expect { existing_association.build(name: 'Fred') }
      .not_to change { existing_book.read_attribute(:author) } }
  end

  describe '#create' do
    specify { expect(association.create).to be_a Author }
    specify { expect(association.create).not_to be_persisted }

    specify { expect(association.create(name: 'Fred')).to be_a Author }
    specify { expect(association.create(name: 'Fred')).to be_persisted }

    specify { expect { association.create }
      .not_to change { book.read_attribute(:author) } }
    specify { expect { association.create(name: 'Fred') }
      .to change { book.read_attribute(:author) }.from(nil).to('name' => 'Fred') }

    specify { expect { existing_association.create }
      .not_to change { existing_book.read_attribute(:author) } }
    specify { expect { existing_association.create(name: 'Fred') }
      .to change { existing_book.read_attribute(:author) }.from('name' => 'Johny').to('name' => 'Fred') }
  end

  describe '#create!' do
    specify { expect { association.create! }.to raise_error ActiveData::ValidationError }

    specify { expect(association.create!(name: 'Fred')).to be_a Author }
    specify { expect(association.create!(name: 'Fred')).to be_persisted }

    specify { expect { association.create! rescue nil }
      .not_to change { book.read_attribute(:author) } }
    specify { expect { association.create! rescue nil }
      .to change { association.reader.try(:attributes) }.from(nil).to('name' => nil) }
    specify { expect { association.create(name: 'Fred') }
      .to change { book.read_attribute(:author) }.from(nil).to('name' => 'Fred') }

    specify { expect { existing_association.create! rescue nil }
      .not_to change { existing_book.read_attribute(:author) } }
    specify { expect { existing_association.create! rescue nil }
      .to change { existing_association.reader.try(:attributes) }.from('name' => 'Johny').to('name' => nil) }
    specify { expect { existing_association.create!(name: 'Fred') }
      .to change { existing_book.read_attribute(:author) }.from('name' => 'Johny').to('name' => 'Fred') }
  end

  describe '#save' do
    specify { expect { association.build; association.save }.to change { association.target.try(:persisted?) }.to(false) }
    specify { expect { association.build(name: 'Fred'); association.save }.to change { association.target.try(:persisted?) }.to(true) }
    specify { expect { existing_association.target.mark_for_destruction; existing_association.save }.to change { existing_association.target.destroyed? }.to(true) }
  end

  describe '#save!' do
    specify { expect { association.build; association.save! }.to raise_error ActiveData::AssociationNotSaved }
    specify { expect { association.build(name: 'Fred'); association.save! }.to change { association.target.try(:persisted?) }.to(true) }
    specify { expect { existing_association.target.mark_for_destruction; existing_association.save! }.to change { existing_association.target.destroyed? }.to(true) }
  end

  describe '#target' do
  end

  describe '#target' do
    specify { expect(association.target).to be_nil }
    specify { expect(existing_association.target).to eq(existing_book.author) }
    specify { expect { association.build }.to change { association.target }.to(an_instance_of(Author)) }
  end

  describe '#loaded?' do
    let(:new_author) { Author.new(name: 'Morty') }

    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.build }.to change { association.loaded? }.to(true) }
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
      before { association.build(name: 'Fred') }
      specify { expect { association.reload }
        .to change { association.reader.try(:attributes) }.from('name' => 'Fred').to(nil) }
    end

    context do
      before { existing_association.build(name: 'Fred') }
      specify { expect { existing_association.reload }
        .to change { existing_association.reader.try(:attributes) }
        .from('name' => 'Fred').to('name' => 'Johny') }
    end
  end

  describe '#clear' do
    specify { expect(association.clear).to eq(true) }
    specify { expect { association.clear }.not_to change { association.reader } }

    specify { expect(existing_association.clear).to eq(true) }
    specify { expect { existing_association.clear }
      .to change { existing_association.reader.try(:attributes) }.from('name' => 'Johny').to(nil) }
    specify { expect { existing_association.clear }
      .to change { existing_book.read_attribute(:author) }.from('name' => 'Johny').to(nil) }

    context do
      before { Author.send(:include, ActiveData::Model::Callbacks) }
      before { Author.before_destroy { false } }
      specify { expect(existing_association.clear).to eq(false) }
      specify { expect { existing_association.clear }
        .not_to change { existing_association.reader } }
      specify { expect { existing_association.clear }
        .not_to change { existing_book.read_attribute(:author).symbolize_keys } }
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to be_nil }

    specify { expect(existing_association.reader).to be_a Author }
    specify { expect(existing_association.reader).to be_persisted }

    context do
      before { association.build }
      specify { expect(association.reader).to be_a Author }
      specify { expect(association.reader).not_to be_persisted }
      specify { expect(association.reader(true)).to be_nil }
    end

    context do
      before { existing_association.build(name: 'Fred') }
      specify { expect(existing_association.reader.name).to eq('Fred') }
      specify { expect(existing_association.reader(true).name).to eq('Johny') }
    end
  end

  describe '#writer' do
    let(:new_author) { Author.new(name: 'Morty') }
    let(:invalid_author) { Author.new }

    context 'new owner' do
      let(:book) do
        Book.new.tap do |book|
          book.send(:mark_persisted!)
        end
      end

      specify { expect { association.writer(nil) }
        .not_to change { book.read_attribute(:author) } }
      specify { expect { association.writer(new_author) }
        .to change { association.reader.try(:attributes) }.from(nil).to('name' => 'Morty') }
      specify { expect { association.writer(new_author) }
        .to change { book.read_attribute(:author) }.from(nil).to('name' => 'Morty') }

      specify { expect { association.writer(invalid_author) }
        .to raise_error ActiveData::AssociationNotSaved }
      specify { expect { association.writer(invalid_author) rescue nil }
        .not_to change { association.reader } }
      specify { expect { association.writer(invalid_author) rescue nil }
        .not_to change { book.read_attribute(:author) } }
    end

    context 'persisted owner' do
      specify { expect { association.writer(stub_model(:dummy).new) }
        .to raise_error ActiveData::AssociationTypeMismatch }

      specify { expect(association.writer(nil)).to be_nil }
      specify { expect(association.writer(new_author)).to eq(new_author) }
      specify { expect { association.writer(nil) }
        .not_to change { book.read_attribute(:author) } }
      specify { expect { association.writer(new_author) }
        .to change { association.reader.try(:attributes) }.from(nil).to('name' => 'Morty') }
      specify { expect { association.writer(new_author) }
        .not_to change { book.read_attribute(:author) } }

      specify { expect { association.writer(invalid_author) }
        .to change { association.reader.try(:attributes) }.from(nil).to('name' => nil) }
      specify { expect { association.writer(invalid_author) }
        .not_to change { book.read_attribute(:author) } }

      specify { expect { existing_association.writer(stub_model(:dummy).new) rescue nil }
        .not_to change { existing_book.read_attribute(:author) } }
      specify { expect { existing_association.writer(stub_model(:dummy).new) rescue nil }
        .not_to change { existing_association.reader } }

      specify { expect(existing_association.writer(nil)).to be_nil }
      specify { expect(existing_association.writer(new_author)).to eq(new_author) }
      specify { expect { existing_association.writer(nil) }
        .to change { existing_book.read_attribute(:author) }.from('name' => 'Johny').to(nil) }
      specify { expect { existing_association.writer(new_author) }
        .to change { existing_association.reader.try(:attributes) }
        .from('name' => 'Johny').to('name' => 'Morty') }
      specify { expect { existing_association.writer(new_author) }
        .to change { existing_book.read_attribute(:author) }
        .from('name' => 'Johny').to('name' => 'Morty') }

      specify { expect { existing_association.writer(invalid_author) }
        .to raise_error ActiveData::AssociationNotSaved }
      specify { expect { existing_association.writer(invalid_author) rescue nil }
        .not_to change { existing_association.reader } }
      specify { expect { existing_association.writer(invalid_author) rescue nil }
        .not_to change { existing_book.read_attribute(:author) } }
    end
  end
end

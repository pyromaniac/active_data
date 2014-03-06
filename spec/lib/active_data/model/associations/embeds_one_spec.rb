# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsOne do
  before do
    stub_model(:author) do
      attribute :name
      validates :name, presence: true
    end

    stub_model(:book) do
      attribute :title
      embeds_one :author
      define_save { true }
    end
  end

  let(:book) { Book.new }
  let(:association) { book.association(:author) }

  let(:existing_book) { Book.instantiate title: 'My Life', author: {'name' => 'Johny'} }
  let(:existing_association) { existing_book.association(:author) }

  describe 'book#association' do
    specify { association.should be_a described_class }
    specify { association.should == book.association(:author) }
  end

  describe '#build' do
    specify { association.build.should be_a Author }
    specify { association.build.should_not be_persisted }

    specify { expect { association.build(name: 'Fred') }
      .not_to change { book.read_attribute(:author) } }

    specify { expect { existing_association.build(name: 'Fred') }
      .not_to change { existing_book.read_attribute(:author) } }
  end

  describe '#create' do
    specify { association.create.should be_a Author }
    specify { association.create.should_not be_persisted }

    specify { association.create(name: 'Fred').should be_a Author }
    specify { association.create(name: 'Fred').should be_persisted }

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

    specify { association.create!(name: 'Fred').should be_a Author }
    specify { association.create!(name: 'Fred').should be_persisted }

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
    specify { expect { association.build; association.save }.to change { association.load_target.try(:persisted?) }.to(false) }
    specify { expect { association.build(name: 'Fred'); association.save }.to change { association.load_target.try(:persisted?) }.to(true) }
    specify { expect { existing_association.load_target.mark_for_destruction; existing_association.save }.to change { existing_association.load_target.destroyed? }.to(true) }
  end

  describe '#save!' do
    specify { expect { association.build; association.save! }.to raise_error ActiveData::AssociationNotSaved }
    specify { expect { association.build(name: 'Fred'); association.save! }.to change { association.load_target.try(:persisted?) }.to(true) }
    specify { expect { existing_association.load_target.mark_for_destruction; existing_association.save! }.to change { existing_association.load_target.destroyed? }.to(true) }
  end

  describe '#target' do
    specify { existing_association.target.should be_nil }
    specify do
      existing_association.load_target
      existing_association.target.should == existing_book.author
    end
    specify { expect { association.build }.to change { association.target }.to(an_instance_of(Author)) }
  end

  describe '#load_target' do
    specify { association.load_target.should == nil }
    specify { existing_association.load_target.should == existing_book.author }
  end

  describe '#loaded?' do
    let(:new_author) { Author.new(name: 'Morty') }

    specify { association.loaded?.should == false }
    specify { expect { association.load_target }.to change { association.loaded? }.to(true) }
    specify { expect { association.build }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace(new_author) }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace(nil) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace(new_author) }.to change { existing_association.loaded? }.to(true) }
    specify { expect { existing_association.replace(nil) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { association.reload.should be_nil }

    specify { existing_association.reload.should be_a Author }
    specify { existing_association.reload.should be_persisted }

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
    specify { association.clear.should == true }
    specify { expect { association.clear }.not_to change { association.reader } }

    specify { existing_association.clear.should == true }
    specify { expect { existing_association.clear }
      .to change { existing_association.reader.try(:attributes) }.from('name' => 'Johny').to(nil) }
    specify { expect { existing_association.clear }
      .to change { existing_book.read_attribute(:author) }.from('name' => 'Johny').to(nil) }

    context do
      before { Author.before_destroy { false } }
      specify { existing_association.clear.should == false }
      specify { expect { existing_association.clear }
        .not_to change { existing_association.reader } }
      specify { expect { existing_association.clear }
        .not_to change { existing_book.read_attribute(:author).symbolize_keys } }
    end
  end

  describe '#reader' do
    specify { association.reader.should be_nil }

    specify { existing_association.reader.should be_a Author }
    specify { existing_association.reader.should be_persisted }

    context do
      before { association.build }
      specify { association.reader.should be_a Author }
      specify { association.reader.should_not be_persisted }
      specify { association.reader(true).should be_nil }
    end

    context do
      before { existing_association.build(name: 'Fred') }
      specify { existing_association.reader.name.should == 'Fred' }
      specify { existing_association.reader(true).name.should == 'Johny' }
    end
  end

  describe '#writer' do
    let(:new_author) { Author.new(name: 'Morty') }
    let(:invalid_author) { Author.new }

    context 'new owner' do
      let(:book) { Book.create }

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

      specify { association.writer(nil).should be_nil }
      specify { association.writer(new_author).should == new_author }
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

      specify { existing_association.writer(nil).should be_nil }
      specify { existing_association.writer(new_author).should == new_author }
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

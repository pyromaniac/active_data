require 'spec_helper'

describe ActiveData::Model::Associations::PersistenceAdapters::ActiveRecord do
  before do
    stub_class(:author, ActiveRecord::Base)
  end

  subject(:adapter) { described_class.new(Author, primary_key, scope_proc) }
  let(:primary_key) { :id }
  let(:scope_proc) { nil }

  describe '#build' do
    subject { adapter.build(name: name) }
    let(:name) { 'John Doe' }

    its(:name) { should == name }
    it { is_expected.to be_a Author }
  end

  describe '#find_one' do
    subject { adapter.find_one(nil, author.id) }
    let(:author) { Author.create }

    it { should == author }
  end

  describe '#find_all' do
    subject { adapter.find_all(nil, authors.map(&:id)) }
    let(:authors) { Array.new(2) { Author.create } }

    it { should == authors }
  end

  describe '#scope' do
    subject { adapter.scope(owner, source) }
    let(:authors) { ['John Doe', 'Sam Smith', 'John Smith'].map { |name| Author.create(name: name) } }
    let(:source) { authors[0..1].map(&:id) }
    let(:owner) { nil }

    it { is_expected.to be_a ActiveRecord::Relation }

    context 'without scope_proc' do
      it { should == Author.where(primary_key => source) }
    end

    context 'with scope_proc' do
      let(:scope_proc) { -> { where("name LIKE 'John%'") } }

      its(:to_a) { should == [Author.first] }
    end
  end

  describe '#primary_key_type' do
    subject { adapter.primary_key_type }

    it { should == Integer }
  end
end

# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::EmbedsOne do
  before do
    stub_model(:author) do
      attribute :name
    end

    stub_model(:book) do
      attribute :title
      embeds_one :author
    end
  end
  let(:book) { Book.new }

  specify { book.author.should be_nil }

  describe '#association' do
    specify { book.association(:author).should be_a ActiveData::Model::Associations::Builders::EmbedsOne }
    specify { book.association(:author).should == book.association(:author) }
  end

  describe '#author=' do
    let(:author) { Author.new name: 'Author' }
    specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
    specify { expect { book.author = 'string' }.to raise_error ActiveData::IncorrectEntity }

    context do
      let(:other) { Author.new name: 'Other' }
      before { book.author = other }
      specify { expect { book.author = author }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author = nil }.to change { book.author }.from(other).to(nil) }
    end
  end

  describe '#build_author=' do
    let(:author) { Author.new name: 'Author' }
    specify { book.build_author(name: 'Author').should == author }
    specify { expect { book.build_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
  end

  describe '#create_author=' do
    let(:author) { Author.new name: 'Author' }
    specify { book.create_author(name: 'Author').should == author }
    specify { expect { book.create_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
  end

  describe '#==' do
    let(:author) { Author.new name: 'Author' }
    let(:other) { Author.new name: 'Other' }

    specify { Book.new(author: author).should == Book.new(author: author) }
    specify { Book.new(author: author).should_not == Book.new(author: other) }
    specify { Book.new(author: author).should_not == Book.new }
  end
end

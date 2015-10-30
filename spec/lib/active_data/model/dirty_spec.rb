# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Dirty do
  before do
    stub_class(:author, ActiveRecord::Base) { }
    stub_model :model do
      include ActiveData::Model::Persistence
      include ActiveData::Model::Localization
      include ActiveData::Model::Associations
      include ActiveData::Model::Dirty

      references_one :author
      embeds_one :something do
        attribute :value
      end

      represents :name, of: :author
      attribute :age, Integer
      collection :numbers, Integer
      localized :title
    end
  end

  let(:author) { Author.create!(name: 'Name') }

  specify { expect(Model.new.changes).to eq({}) }
  specify { expect(Model.new.tap { |m| m.create_something(value: 'Value') }.changes).to eq({}) }
  specify { expect(Model.new(author: author).changes).to eq('author_id' => [nil, author.id]) }
  specify { expect(Model.new(author: author, name: 'Name2').changes).to eq('author_id' => [nil, author.id], 'name' => ['Name', 'Name2']) }
  specify { expect(Model.new(age: 'blabla').changes).to eq({}) }
  specify { expect(Model.new(age: '42').changes).to eq('age' => [nil, 42]) }
  specify { expect(Model.instantiate(age: '42').changes).to eq({}) }
  specify { expect(Model.instantiate(age: '42').tap { |m| m.update(age: '43') }.changes).to eq('age' => [42, 43]) }
  specify { expect(Model.new(age: '42').tap { |m| m.update(age: '43') }.changes).to eq('age' => [nil, 43]) }
  specify { expect(Model.new(numbers: '42').changes).to eq('numbers' => [[], [42]]) }

  # Have no idea how should it work right now
  specify { expect(Model.new(title: 'Hello').changes).to eq('title' => [{}, 'Hello']) }
  specify { expect(Model.new(title_translations: {en: 'Hello'}).changes).to eq('title' => [{}, 'Hello']) }
end

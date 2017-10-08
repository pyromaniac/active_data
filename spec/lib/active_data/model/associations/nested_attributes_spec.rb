require 'spec_helper'
require 'shared/nested_attribute_examples'

describe ActiveData::Model::Associations::NestedAttributes do
  context 'embedded nested attributes' do
    before do
      stub_model :user do
        include ActiveData::Model::Associations

        attribute :email, String
        embeds_one :profile
        embeds_many :projects

        accepts_nested_attributes_for :profile, :projects

        def save
          apply_association_changes!
        end
      end
    end

    include_examples 'embedded nested attributes'
  end

  context 'referenced nested attributes' do
    before do
      stub_class(:author, ActiveRecord::Base)
      stub_class(:user, ActiveRecord::Base)

      stub_model :book do
        include ActiveData::Model::Associations
        include ActiveData::Model::Lifecycle

        references_one :author
        references_many :users

        accepts_nested_attributes_for :author, :users
      end
    end

    context 'references_one' do
      let(:book) { Book.new }

      specify { expect { book.author_attributes = {} }.to change { book.author }.to(an_instance_of(Author)) }
      specify { expect { book.author_attributes = {name: 'Author'} }.to change { book.author.try(:name) }.to('Author') }
      specify { expect { book.author_attributes = {id: 42, name: 'Author'} }.to raise_error ActiveData::ObjectNotFound }

      context ':reject_if' do
        context do
          before { Book.accepts_nested_attributes_for :author, reject_if: :all_blank }
          specify { expect { book.author_attributes = {name: ''} }.not_to change { book.author } }
        end

        context do
          before { Book.accepts_nested_attributes_for :author, reject_if: ->(attributes) { attributes['name'].blank? } }
          specify { expect { book.author_attributes = {name: ''} }.not_to change { book.author } }
        end
      end

      context 'existing' do
        let(:author) { Author.create!(name: 'Author') }
        let(:book) { Book.new author: author }

        specify { expect { book.author_attributes = {id: 42, name: 'Author'} }.to raise_error ActiveData::ObjectNotFound }
        specify { expect { book.author_attributes = {id: author.id.to_s, name: 'Author 1'} }.to change { book.author.name }.to('Author 1') }
        specify { expect { book.author_attributes = {name: 'Author 1'} }.to change { book.author.name }.to('Author 1') }
        specify { expect { book.author_attributes = {name: 'Author 1', _destroy: '1'} }.not_to change { book.author.name } }
        specify do
          expect do
            book.author_attributes = {name: 'Author 1', _destroy: '1'}
            book.save { true }
          end.not_to change { book.author.name }
        end
        specify { expect { book.author_attributes = {id: author.id.to_s, name: 'Author 1', _destroy: '1'} }.to change { book.author.name }.to('Author 1') }
        specify do
          expect do
            book.author_attributes = {id: author.id.to_s, name: 'Author 1', _destroy: '1'}
            book.save { true }
          end.to change { book.author.name }.to('Author 1')
        end

        context ':allow_destroy' do
          before { Book.accepts_nested_attributes_for :author, allow_destroy: true }

          specify { expect { book.author_attributes = {name: 'Author 1', _destroy: '1'} }.not_to change { book.author.name } }
          specify do
            expect do
              book.author_attributes = {name: 'Author 1', _destroy: '1'}
              book.save { true }
            end.not_to change { book.author.name }
          end
          specify { expect { book.author_attributes = {id: author.id.to_s, name: 'Author 1', _destroy: '1'} }.to change { book.author.name }.to('Author 1') }
          specify do
            expect do
              book.author_attributes = {id: author.id.to_s, name: 'Author 1', _destroy: '1'}
              book.save { true }
            end.to change { book.author }.to(nil)
          end
        end

        context ':update_only' do
          before { Book.accepts_nested_attributes_for :author, update_only: true }

          specify do
            expect { book.author_attributes = {id: 42, name: 'Author 1'} }
              .to change { book.author.name }.to('Author 1')
          end
        end
      end

      context 'references_many' do
        let(:book) { Book.new }

        specify { expect { book.users_attributes = {} }.not_to change { book.users } }
        specify do
          expect { book.users_attributes = [{email: 'User 1'}, {email: 'User 2'}] }
            .to change { book.users.map(&:email) }.to(['User 1', 'User 2'])
        end
        specify do
          expect { book.users_attributes = {1 => {email: 'User 1'}, 2 => {email: 'User 2'}} }
            .to change { book.users.map(&:email) }.to(['User 1', 'User 2'])
        end
        specify do
          expect { book.users_attributes = [{id: 33, email: 'User 1'}, {email: 'User 2'}] }
            .to raise_error ActiveData::ObjectNotFound
        end
        specify do
          expect { book.users_attributes = [{email: ''}, {email: 'User 2'}] }
            .to change { book.users.map(&:email) }.to(['', 'User 2'])
        end

        context ':limit' do
          before { Book.accepts_nested_attributes_for :users, limit: 1 }

          specify do
            expect { book.users_attributes = [{email: 'User 1'}] }
              .to change { book.users.map(&:email) }.to(['User 1'])
          end
          specify do
            expect { book.users_attributes = [{email: 'User 1'}, {email: 'User 2'}] }
              .to raise_error ActiveData::TooManyObjects
          end
        end

        context ':reject_if' do
          context do
            before { Book.accepts_nested_attributes_for :users, reject_if: :all_blank }
            specify do
              expect { book.users_attributes = [{email: ''}, {email: 'User 2'}] }
                .to change { book.users.map(&:email) }.to(['User 2'])
            end
          end

          context do
            before { Book.accepts_nested_attributes_for :users, reject_if: ->(attributes) { attributes['email'].blank? } }
            specify do
              expect { book.users_attributes = [{email: ''}, {email: 'User 2'}] }
                .to change { book.users.map(&:email) }.to(['User 2'])
            end
          end

          context do
            before { Book.accepts_nested_attributes_for :users, reject_if: ->(attributes) { attributes['foobar'].blank? } }
            specify do
              expect { book.users_attributes = [{email: ''}, {email: 'User 2'}] }
                .not_to change { book.users }
            end
          end
        end

        context 'existing' do
          let(:users) { Array.new(2) { |i| User.create!(email: "User #{i.next}").tap { |pr| pr.id = 42 + i } } }
          let(:book) { Book.new users: users }

          specify do
            expect do
              book.users_attributes = [
                {id: users.first.id, email: 'User 3'},
                {email: 'User 4'}
              ]
            end.to change { book.users.map(&:email) }.to(['User 3', 'User 2', 'User 4'])
          end
          specify do
            expect do
              book.users_attributes = [
                {id: users.first.id, email: 'User 3'},
                {id: 33, email: 'User 4'}
              ]
            end.to raise_error ActiveData::ObjectNotFound
          end
          specify do
            expect do
              book.users_attributes = [
                {id: users.first.id, email: 'User 3'},
                {id: 33, email: 'User 4', _destroy: 1}
              ]
            end.to raise_error ActiveData::ObjectNotFound
          end
          specify do
            expect do
              book.users_attributes = {
                1 => {id: users.first.id, email: 'User 3'},
                2 => {email: 'User 4'}
              }
            end.to change { book.users.map(&:email) }.to(['User 3', 'User 2', 'User 4'])
          end
          specify do
            expect do
              book.users_attributes = [
                {id: users.first.id, email: 'User 3', _destroy: '1'},
                {email: 'User 4', _destroy: '1'}
              ]
            end.to change { book.users.map(&:email) }.to(['User 3', 'User 2'])
          end
          specify do
            expect do
              book.users_attributes = [
                {id: users.first.id, email: 'User 3', _destroy: '1'},
                {email: 'User 4', _destroy: '1'}
              ]
              book.save { true }
            end.to change { book.users.map(&:email) }.to(['User 3', 'User 2'])
          end

          context ':allow_destroy' do
            before { Book.accepts_nested_attributes_for :users, allow_destroy: true }

            specify do
              expect do
                book.users_attributes = [
                  {id: users.first.id, email: 'User 3', _destroy: '1'},
                  {email: 'User 4', _destroy: '1'}
                ]
              end.to change { book.users.map(&:email) }.to(['User 3', 'User 2'])
            end
            specify do
              expect do
                book.users_attributes = [
                  {id: users.first.id, email: 'User 3', _destroy: '1'},
                  {email: 'User 4', _destroy: '1'}
                ]
                book.save { true }
              end.to change { book.users.map(&:email) }.to(['User 2'])
            end
          end

          context ':update_only' do
            before { Book.accepts_nested_attributes_for :users, update_only: true }

            specify do
              expect do
                book.users_attributes = [
                  {id: users.first.id, email: 'User 3'},
                  {email: 'User 4'}
                ]
              end.to change { book.users.map(&:email) }.to(['User 3', 'User 2'])
            end

            specify do
              expect do
                book.users_attributes = [
                  {id: users.last.id, email: 'User 3'},
                  {id: users.first.id.pred, email: 'User 0'}
                ]
              end.to raise_error ActiveData::ObjectNotFound
            end
          end
        end
      end
    end
  end

  describe '#assign_attributes' do
    specify 'invent a good example'
  end
end

# encoding: UTF-8
require 'spec_helper'
require 'lib/active_data/model/nested_attributes'

describe ActiveData::Model::Associations::NestedAttributes do
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

  context do
    before do
      stub_model :project do
        include ActiveData::Model::Primary
        include ActiveData::Model::Lifecycle

        primary :identifier
        attribute :title, String

        validates :title, presence: true
      end
      
      stub_model :user do
        include ActiveData::Model::Associations

        embeds_many :projects

        accepts_nested_attributes_for :projects
      end
    end

    let(:user) { User.new(attributes) }
    let(:attributes) do
      {
        projects_attributes: {
          1 => { title: 'Project 1' },
          2 => { title: '' },
        }
      }
    end

    specify 'validation errors are indexed with params index' do
      user.validate
      expect(user.errors.messages).to eq({'projects.2.title' => ["Can't be blank"]})
    end

    context 'item with invalid attributes marked for destruction' do
      let(:attributes) do
        {
          projects_attributes: {
            1 => { title: 'Project 1' },
            2 => { title: '', _destroy: '' },
          }
        }
      end

      specify { expect(user).to be_valid }
    end
  end

  include_examples 'nested attributes'
end

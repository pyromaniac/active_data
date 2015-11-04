# encoding: UTF-8
require 'spec_helper'
require 'lib/active_data/model/nested_attributes'

describe ActiveData::Model::Associations::NestedAttributes do
  before do
    stub_model :user do
      include ActiveData::Model::Associations

      attribute :email, type: String
      embeds_one :profile
      embeds_many :projects

      accepts_nested_attributes_for :profile, :projects

      def save
        apply_association_changes!
      end
    end
  end

  include_examples 'nested attributes'
end

require 'spec_helper'
require 'shared/nested_attribute_examples'

describe ActiveData::ActiveRecord::NestedAttributes do
  before do
    stub_class(:user, ActiveRecord::Base) do
      embeds_one :profile
      embeds_many :projects

      accepts_nested_attributes_for :profile, :projects
    end
  end

  include_examples 'nested attributes'
end

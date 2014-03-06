# encoding: UTF-8
require 'spec_helper'
require 'lib/active_data/model/nested_attributes'

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

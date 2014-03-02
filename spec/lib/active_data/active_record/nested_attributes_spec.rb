require 'spec_helper'

describe ActiveData::ActiveRecord::Associations do
  before do
    stub_model(:ability) do
      primary_attribute
      attribute :title, type: String
      attribute :read, type: Boolean, default: false
      attribute :create, type: Boolean, default: false
      attribute :update, type: Boolean, default: false
      attribute :delete, type: Boolean, default: false

      validates :title, presence: true
    end

    stub_model(:tracking) do
      primary_attribute
      attribute :referer, type: String
      attribute :ip_address, type: String
    end

    stub_class(:user, ActiveRecord::Base) do
      embeds_many :abilities
      embeds_one :tracking

      validates :abilities, associated: true
    end
  end
end

require 'spec_helper'

describe ActiveData::ActiveRecord::Associations do
  before do
    stub_model(:ability) do
      attribute :title, type: String
      attribute :read, type: Boolean, default: false
      attribute :create, type: Boolean, default: false
      attribute :update, type: Boolean, default: false
      attribute :delete, type: Boolean, default: false

      validates :title, presence: true
    end

    stub_model(:tracking) do
      attribute :referer, type: String
      attribute :ip_address, type: String
    end

    stub_class(:user, ActiveRecord::Base) do
      embeds_many :abilities
      embeds_one :tracking
    end
  end

  subject(:user) { User.new }

  its(:abilities) { should = [] }
  its(:tracking) { should = nil }
end

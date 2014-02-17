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

      validates :abilities, associated: true
    end
  end

  subject(:user) { User.new }

  its(:abilities) { should = [] }
  its(:tracking) { should = nil }

  describe '#abilities' do
    specify { expect { user.abilities << Ability.new }
      .not_to change { user.read_attribute(:abilities) } }
    specify { expect { user.abilities << Ability.new(title: 'First') }
      .to change { user.read_attribute(:abilities) }.from(nil)
      .to([{title: 'First', read: false, create: false, update: false, delete: false}].to_json) }
    specify { expect { user.abilities << Ability.new(title: 'First') }
      .to change { user.abilities.reload.count }.from(0).to(1) }
    specify do
      user.abilities << Ability.new(title: 'First')
      user.save
      user.reload.abilities.first.title.should == 'First'
    end
  end

  describe '#tracking' do
    specify { expect { user.tracking = Tracking.new(referer: 'google.com') }
      .to change { user.read_attribute(:tracking) }.from(nil)
      .to({referer: 'google.com', ip_address: nil}.to_json) }
    specify { expect { user.tracking = Tracking.new(referer: 'google.com') }
      .to change { user.tracking }.from(nil).to(an_instance_of(Tracking)) }
    specify do
      user.tracking = Tracking.new(referer: 'google.com')
      user.save
      user.reload.tracking.referer.should == 'google.com'
    end
  end
end

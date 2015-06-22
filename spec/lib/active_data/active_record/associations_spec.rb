require 'spec_helper'

describe ActiveData::ActiveRecord::Associations do
  before do
    stub_model(:project) do
      include ActiveData::Model::Lifecycle

      attribute :title, type: String

      validates :title, presence: true
    end

    stub_model(:profile) do
      include ActiveData::Model::Lifecycle

      attribute :first_name, type: String
      attribute :last_name, type: String
    end

    stub_class(:user, ActiveRecord::Base) do
      embeds_many :projects
      embeds_one :profile

      validates :projects, associated: true
    end
  end


  its(:projects) { should = [] }
  its(:profile) { should = nil }

  context 'new owner' do
    subject(:user) { User.new }

    describe '#projects' do
      specify { expect { user.projects << Project.new }
        .not_to change { user.read_attribute(:projects) } }
      specify { expect { user.projects << Project.new(title: 'First') }
        .not_to change { user.read_attribute(:projects) } }
      specify { expect { user.projects << Project.new(title: 'First') }
        .not_to change { user.projects.reload.count } }
      specify do
        user.projects << Project.new(title: 'First')
        user.save
        expect(user.reload.projects.first.title).to eq('First')
      end
    end

    describe '#profile' do
      specify { expect { user.profile = Profile.new(first_name: 'google.com') }
        .not_to change { user.read_attribute(:profile) } }
      specify { expect { user.profile = Profile.new(first_name: 'google.com') }
        .to change { user.profile }.from(nil).to(an_instance_of(Profile)) }
      specify do
        user.profile = Profile.new(first_name: 'google.com')
        user.save
        expect(user.reload.profile.first_name).to eq('google.com')
      end
    end
  end

  context 'persisted owner' do
    subject(:user) { User.create }

    describe '#projects' do
      specify { expect { user.projects << Project.new }
        .not_to change { user.read_attribute(:projects) } }
      specify { expect { user.projects << Project.new(title: 'First') }
        .to change { user.read_attribute(:projects) }.from(nil)
        .to([{title: 'First'}].to_json) }
      specify { expect { user.projects << Project.new(title: 'First') }
        .to change { user.projects.reload.count }.from(0).to(1) }
      specify do
        user.projects << Project.new(title: 'First')
        user.save
        expect(user.reload.projects.first.title).to eq('First')
      end
    end

    describe '#profile' do
      specify { expect { user.profile = Profile.new(first_name: 'google.com') }
        .to change { user.read_attribute(:profile) }.from(nil)
        .to({first_name: 'google.com', last_name: nil}.to_json) }
      specify { expect { user.profile = Profile.new(first_name: 'google.com') }
        .to change { user.profile }.from(nil).to(an_instance_of(Profile)) }
      specify do
        user.profile = Profile.new(first_name: 'google.com')
        user.save
        expect(user.reload.profile.first_name).to eq('google.com')
      end
    end
  end
end

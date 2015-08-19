require 'spec_helper'

describe ActiveData::ActiveRecord::Associations do
  before do
    stub_model(:project) do
      include ActiveData::Model::Lifecycle
      include ActiveData::Model::Associations

      attribute :title, type: String

      validates :title, presence: true

      embeds_one :author do
        attribute :name, String

        validates :name, presence: true
      end
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
        .to change { user.projects.reload.count }.from(0).to(1) }
      specify {
        user.projects << Project.new(title: 'First')
        user.save
        expect(user.reload.projects.first.title).to eq('First') }

      context do
        let(:project) { Project.new(title: 'First') }
        before { project.build_author(name: 'Author') }

        specify { expect { user.projects << project }
          .to change { user.attributes['projects'] }.from(nil)
          .to([{title: 'First', author: {name: 'Author'}}].to_json) }
        specify { expect { user.projects << project; user.save }
          .to change { user.reload.attributes['projects'] }.from(nil)
          .to([{title: 'First', author: {name: 'Author'}}].to_json) }
      end
    end

    describe '#profile' do
      specify { expect { user.profile = Profile.new(first_name: 'google.com') }
        .to change { user.profile }.from(nil).to(an_instance_of(Profile)) }
      specify {
        user.profile = Profile.new(first_name: 'google.com')
        user.save
        expect(user.reload.profile.first_name).to eq('google.com') }
      specify { expect { user.profile = Profile.new(first_name: 'google.com') }
        .to change { user.attributes['profile'] }.from(nil)
        .to({first_name: 'google.com', last_name: nil}.to_json) }
      specify { expect { user.profile = Profile.new(first_name: 'google.com'); user.save }
        .to change { user.reload.attributes['profile'] }.from(nil)
        .to({first_name: 'google.com', last_name: nil}.to_json) }
    end
  end

  context 'class determine errors' do
    specify do
      expect { stub_class(:book, ActiveRecord::Base) do
        embeds_one :author, class_name: 'Borogoves'
      end.reflect_on_association(:author).klass }.to raise_error NameError
    end

    specify do
      expect { stub_class(:user, ActiveRecord::Base) do
        embeds_many :projects, class_name: 'Borogoves' do
          attribute :title
        end
      end.reflect_on_association(:projects).klass }.to raise_error NameError
    end
  end

  context 'on the fly' do
    before do
      stub_class(:user, ActiveRecord::Base) do
        embeds_many :projects do
          attribute :title, type: String
        end
        embeds_one :profile, class_name: 'Profile' do
          attribute :age, type: Integer
        end
      end
    end

    specify { expect(User.reflect_on_association(:projects).klass).to eq(User::Project) }
    specify { expect(User.new.projects).to eq([]) }
    specify { expect(User.new.tap { |u| u.projects.create(title: 'Project') }.projects).to be_a(ActiveData::Model::Associations::Collection::Embedded) }
    specify { expect(User.new.tap { |u| u.projects.create(title: 'Project') }.read_attribute(:projects)).to eq([{title: 'Project'}].to_json) }

    specify { expect(User.reflect_on_association(:profile).klass).to eq(User::Profile) }
    specify { expect(User.reflect_on_association(:profile).klass).to be < Profile }
    specify { expect(User.new.profile).to be_nil }
    specify { expect(User.new.tap { |u| u.create_profile(first_name: 'Profile') }.profile).to be_a(User::Profile) }
    specify { expect(User.new.tap { |u| u.create_profile(first_name: 'Profile') }.read_attribute(:profile)).to eq({first_name: 'Profile', last_name: nil, age: nil}.to_json) }
  end
end

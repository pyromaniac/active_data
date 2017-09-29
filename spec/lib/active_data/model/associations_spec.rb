require 'spec_helper'

describe ActiveData::Model::Associations do
  context do
    before do
      stub_model(:nobody) do
        include ActiveData::Model::Associations
      end
      stub_model(:project) do
        include ActiveData::Model::Lifecycle
      end
      stub_model(:user, Nobody) do
        include ActiveData::Model::Associations
        embeds_many :projects
      end
      stub_model(:manager, Nobody) do
        include ActiveData::Model::Associations
        embeds_one :managed_project, class_name: 'Project'
      end
      stub_model(:admin, User) do
        include ActiveData::Model::Associations
        embeds_many :admin_projects, class_name: 'Project'

        alias_association :own_projects, :admin_projects
      end
    end

    describe '#reflections' do
      specify { expect(Nobody.reflections.keys).to eq([]) }
      specify { expect(User.reflections.keys).to eq([:projects]) }
      specify { expect(Manager.reflections.keys).to eq([:managed_project]) }
      specify { expect(Admin.reflections.keys).to eq(%i[projects admin_projects]) }
    end

    describe '#reflect_on_association' do
      specify { expect(Nobody.reflect_on_association(:blabla)).to be_nil }
      specify { expect(Admin.reflect_on_association('projects')).to be_a ActiveData::Model::Associations::Reflections::EmbedsMany }
      specify { expect(Admin.reflect_on_association('own_projects').name).to eq(:admin_projects) }
      specify { expect(Manager.reflect_on_association(:managed_project)).to be_a ActiveData::Model::Associations::Reflections::EmbedsOne }
    end
  end

  context 'class determine errors' do
    specify do
      expect do
        stub_model do
          include ActiveData::Model::Associations

          embeds_one :author, class_name: 'Borogoves'
        end.reflect_on_association(:author).data_source end.to raise_error NameError
    end

    specify do
      expect do
        stub_model(:user) do
          include ActiveData::Model::Associations

          embeds_many :projects, class_name: 'Borogoves' do
            attribute :title
          end
        end.reflect_on_association(:projects).data_source end.to raise_error NameError
    end
  end

  context do
    before do
      stub_model(:project) do
        include ActiveData::Model::Lifecycle
        include ActiveData::Model::Associations

        attribute :title, String

        validates :title, presence: true

        embeds_one :author do
          attribute :name, String

          validates :name, presence: true
        end
      end

      stub_model(:profile) do
        include ActiveData::Model::Lifecycle

        attribute :first_name, String
        attribute :last_name, String

        validates :first_name, presence: true
      end

      stub_model(:user) do
        include ActiveData::Model::Associations

        attribute :login, Object

        validates :login, presence: true

        embeds_one :profile
        embeds_many :projects

        alias_association :my_profile, :profile
      end
    end

    let(:user) { User.new }

    specify { expect(user.projects).to eq([]) }
    specify { expect(user.profile).to be_nil }

    describe '.inspect' do
      specify { expect(User.inspect).to eq('User(profile: EmbedsOne(Profile), projects: EmbedsMany(Project), login: Object)') }
    end

    describe '.association_names' do
      specify { expect(User.association_names).to eq(%i[profile projects]) }
    end

    describe '#inspect' do
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      specify do
        expect(User.new(login: 'Login', profile: profile, projects: [project]).inspect)
          .to eq('#<User profile: #<EmbedsOne #<Profile first_name: "Name", last_name: nil>>, projects: #<EmbedsMany [#<Project author: #<EmbedsOne nil>, title: "P...]>, login: "Login">')
      end
    end

    describe '#==' do
      let(:project) { Project.new title: 'Project' }
      let(:other) { Project.new title: 'Other' }

      specify { expect(User.new(projects: [project])).to eq(User.new(projects: [project])) }
      specify { expect(User.new(projects: [project])).not_to eq(User.new(projects: [other])) }
      specify { expect(User.new(projects: [project])).not_to eq(User.new) }

      specify { expect(User.new(projects: [project])).to eql(User.new(projects: [project])) }
      specify { expect(User.new(projects: [project])).not_to eql(User.new(projects: [other])) }
      specify { expect(User.new(projects: [project])).not_to eql(User.new) }

      context do
        before { User.send(:include, ActiveData::Model::Primary) }
        let(:user) { User.new(projects: [project]) }

        specify { expect(user).to eq(user.clone.tap { |b| b.projects(author: project) }) }
        specify { expect(user).to eq(user.clone.tap { |b| b.projects(author: other) }) }

        specify { expect(user).to eql(user.clone.tap { |b| b.projects(author: project) }) }
        specify { expect(user).to eql(user.clone.tap { |b| b.projects(author: other) }) }
      end
    end

    describe '#association' do
      specify { expect(user.association(:projects)).to be_a(ActiveData::Model::Associations::EmbedsMany) }
      specify { expect(user.association(:profile)).to be_a(ActiveData::Model::Associations::EmbedsOne) }
      specify { expect(user.association(:blabla)).to be_nil }
      specify { expect(user.association('my_profile').reflection.name).to eq(:profile) }
      specify { expect(user.association('my_profile')).to equal(user.association(:profile)) }
    end

    describe '#association_names' do
      specify { expect(user.association_names).to eq(%i[profile projects]) }
    end

    describe '#apply_association_changes!' do
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      let(:user) { User.new(profile: profile, projects: [project]) }
      before { project.build_author(name: 'Author') }

      specify do
        expect { user.apply_association_changes! }.to change { user.attributes['profile'] }
          .from(nil).to('first_name' => 'Name', 'last_name' => nil)
      end
      specify do
        expect { user.apply_association_changes! }.to change { user.attributes['projects'] }
          .from(nil).to([{'title' => 'Project', 'author' => {'name' => 'Author'}}])
      end

      context do
        let(:project) { Project.new }
        specify { expect { user.apply_association_changes! }.to raise_error ActiveData::AssociationChangesNotApplied }
      end
    end

    describe '#instantiate' do
      before { User.send(:include, ActiveData::Model::Persistence) }
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      let(:user) { User.new(profile: profile, projects: [project]) }
      before { project.build_author(name: 'Author') }

      specify { expect(User.instantiate(JSON.parse(user.to_json))).to eq(user) }
      specify do
        expect(User.instantiate(JSON.parse(user.to_json))
        .tap { |u| u.projects.first.author.name = 'Other' }).not_to eq(user)
      end
    end
  end
end

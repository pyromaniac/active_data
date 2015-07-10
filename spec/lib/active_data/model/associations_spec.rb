# encoding: UTF-8
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
      end
    end

    describe '#reflections' do
      specify { expect(Nobody.reflections.keys).to eq([]) }
      specify { expect(User.reflections.keys).to eq([:projects]) }
      specify { expect(Manager.reflections.keys).to eq([:managed_project]) }
      specify { expect(Admin.reflections.keys).to eq([:projects, :admin_projects]) }
    end

    describe '#reflect_on_association' do
      specify { expect(Nobody.reflect_on_association(:blabla)).to be_nil }
      specify { expect(Admin.reflect_on_association('projects')).to be_a ActiveData::Model::Associations::Reflections::EmbedsMany }
      specify { expect(Manager.reflect_on_association(:managed_project)).to be_a ActiveData::Model::Associations::Reflections::EmbedsOne }
    end
  end

  context 'class determine errors' do
    specify do
      expect { stub_model do
        include ActiveData::Model::Associations

        embeds_one :author, class_name: 'Borogoves'
      end.reflect_on_association(:author).klass }.to raise_error(/Can not determine class for `#<Class:\w+>#author` association/)
    end

    specify do
      expect { stub_model(:user) do
        include ActiveData::Model::Associations

        embeds_many :projects, class_name: 'Borogoves' do
          attribute :title
        end
      end.reflect_on_association(:projects).klass }.to raise_error 'Can not determine superclass for `User#projects` association'
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

        attribute :login

        validates :login, presence: true

        embeds_one :profile
        embeds_many :projects
      end
    end

    let(:user) { User.new }

    its(:projects) { should = [] }
    its(:profile) { should = nil }

    describe '.inspect' do
      specify { expect(User.inspect).to eq('User(profile: EmbedsOne(Profile), projects: EmbedsMany(Project), login: Object)') }
    end

    describe '#inspect' do
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      specify { expect(User.new(login: 'Login', profile: profile, projects: [project]).inspect)
        .to eq('#<User profile: #<EmbedsOne #<Profile first_name: "Name", last_name: nil>>, projects: #<EmbedsMany [#<Project author: #<EmbedsOne nil>, title: "P...]>, login: "Login">') }
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
    end

    describe '#association_names' do
      specify { expect(user.association_names).to eq([:profile, :projects]) }
    end

    describe '#save_associations!' do
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      let(:user) { User.new(profile: profile, projects: [project]) }
      before { project.build_author(name: 'Author') }

      specify { expect { user.save_associations! }.to change { user.attributes['profile'] }
        .from(nil).to('first_name' => 'Name', 'last_name' => nil) }
      specify { expect { user.save_associations! }.to change { user.attributes['projects'] }
        .from(nil).to([{ 'title' => 'Project', 'author' => { 'name' => 'Author' } }]) }

      context do
        let(:project) { Project.new }
        specify { expect { user.save_associations! }.to raise_error ActiveData::AssociationNotSaved }
      end
    end

    describe '#instantiate' do
      before { User.send(:include, ActiveData::Model::Persistence) }
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      let(:user) { User.new(profile: profile, projects: [project]) }
      before { project.build_author(name: 'Author') }

      specify { expect(User.instantiate(JSON.parse(user.to_json))).to eq(user) }
      specify { expect(User.instantiate(JSON.parse(user.to_json))
        .tap { |u| u.projects.first.author.name = 'Other' }).not_to eq(user) }
    end

    context '#validate_ancestry, #valid_ancestry?, #invalid_ancestry?' do
      before { User.send(:include, ActiveData::Model::Persistence) }
      let(:profile) { Profile.new first_name: 'Name' }
      let(:project) { Project.new title: 'Project' }
      let(:projects) { [project] }
      let(:user) { User.new(login: 'Login', profile: profile, projects: projects) }
      let(:author_attributes) { { name: 'Author' } }
      before { project.build_author(author_attributes) }

      specify { expect(user.validate_ancestry).to eq(true) }
      specify { expect(user.validate_ancestry!).to eq(true) }
      specify { expect { user.validate_ancestry! }.not_to raise_error }
      specify { expect(user.valid_ancestry?).to eq(true) }
      specify { expect(user.invalid_ancestry?).to eq(false) }
      specify { expect{ user.validate_ancestry }.not_to change { user.errors.messages } }

      context do
        let(:author_attributes) { {} }
        specify { expect(user.validate_ancestry).to eq(false) }
        specify { expect { user.validate_ancestry! }.to raise_error ActiveData::ValidationError }
        specify { expect(user.valid_ancestry?).to eq(false) }
        specify { expect(user.invalid_ancestry?).to eq(true) }
        specify { expect{ user.validate_ancestry }.to change { user.errors.messages }
          .to(projects: [author: { name: ["can't be blank"] }]) }
      end

      context do
        let(:profile) { Profile.new }
        specify { expect(user.validate_ancestry).to eq(false) }
        specify { expect { user.validate_ancestry! }.to raise_error ActiveData::ValidationError }
        specify { expect(user.valid_ancestry?).to eq(false) }
        specify { expect(user.invalid_ancestry?).to eq(true) }
        specify { expect{ user.validate_ancestry }.to change { user.errors.messages }
          .to(profile: { first_name: ["can't be blank"] }) }
      end

      context do
        let(:projects) { [project, Project.new] }
        specify { expect(user.validate_ancestry).to eq(false) }
        specify { expect { user.validate_ancestry! }.to raise_error ActiveData::ValidationError }
        specify { expect(user.valid_ancestry?).to eq(false) }
        specify { expect(user.invalid_ancestry?).to eq(true) }
        specify { expect{ user.validate_ancestry }.to change { user.errors.messages }
          .to(projects: [nil, { title: ["can't be blank"] }]) }

        context do
          before { user.update(login: '') }
          specify { expect{ user.validate_ancestry }.to change { user.errors.messages }
            .to(projects: [nil, { title: ["can't be blank"] }], login: ["can't be blank"]) }
        end
      end
    end
  end
end

require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::EmbedsMany do
  before do
    stub_model(:project) do
      include ActiveData::Model::Lifecycle
      attribute :title, String
    end
    stub_model(:user) do
      include ActiveData::Model::Associations

      attribute :name, String
      embeds_many :projects
    end
  end
  let(:user) { User.new }

  context ':read, :write' do
    before do
      stub_model(:user) do
        include ActiveData::Model::Persistence
        include ActiveData::Model::Associations

        attribute :name
        embeds_many :projects,
          read: lambda { |reflection, object|
            value = object.read_attribute(reflection.name)
            JSON.parse(value) if value.present?
          },
          write: lambda { |reflection, object, value|
            object.write_attribute(reflection.name, value.to_json)
          }
      end
    end

    let(:user) { User.instantiate name: 'Rick', projects: [{title: 'Genesis'}].to_json }
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }

    specify do
      expect { user.projects.concat([new_project1, new_project2]) }
        .to change { user.read_attribute(:projects) }
        .from([{title: 'Genesis'}].to_json)
        .to([{title: 'Genesis'}, {title: 'Project 1'}, {title: 'Project 2'}].to_json)
    end
  end

  describe '#projects' do
    specify { expect(user.projects).to eq([]) }

    describe '#build' do
      let(:project) { Project.new title: 'Project' }
      specify { expect(user.projects.build(title: 'Project')).to eq(project) }
      specify { expect { user.projects.build(title: 'Project') }.to change { user.projects }.from([]).to([project]) }
    end

    describe '#create' do
      let(:project) { Project.new title: 'Project' }
      specify { expect(user.projects.create(title: 'Project')).to eq(project) }
      specify { expect { user.projects.create(title: 'Project') }.to change { user.projects }.from([]).to([project]) }
    end

    describe '#create!' do
      let(:project) { Project.new title: 'Project' }
      specify { expect(user.projects.create!(title: 'Project')).to eq(project) }
      specify { expect { user.projects.create!(title: 'Project') }.to change { user.projects }.from([]).to([project]) }
    end

    describe '#reload' do
      let(:project) { Project.new title: 'Project' }
      before do
        user.update(projects: [project])
        user.apply_association_changes!
      end
      before { user.projects.build }

      specify { expect(user.projects.count).to eq(2) }
      specify { expect(user.projects.reload).to eq([project]) }
    end

    describe '#concat' do
      let(:project) { Project.new title: 'Project' }
      specify { expect { user.projects.concat project }.to change { user.projects }.from([]).to([project]) }
      specify { expect { user.projects.concat project, 'string' }.to raise_error ActiveData::AssociationTypeMismatch }

      context do
        let(:other) { Project.new title: 'Other' }
        before { user.projects = [other] }
        specify { expect { user.projects.concat project }.to change { user.projects }.from([other]).to([other, project]) }
      end
    end
  end

  describe '#projects=' do
    let(:project) { Project.new title: 'Project' }
    specify { expect { user.projects = [] }.not_to change { user.projects }.from([]) }
    specify { expect { user.projects = [project] }.to change { user.projects }.from([]).to([project]) }
    specify { expect { user.projects = [project, 'string'] }.to raise_error ActiveData::AssociationTypeMismatch }

    context do
      let(:other) { Project.new title: 'Other' }
      before { user.projects = [other] }
      specify { expect { user.projects = [project] }.to change { user.projects }.from([other]).to([project]) }
      specify { expect { user.projects = [] }.to change { user.projects }.from([other]).to([]) }
    end
  end

  context 'on the fly' do
    context do
      before do
        stub_model(:user) do
          include ActiveData::Model::Associations

          attribute :title, String
          embeds_many :projects do
            attribute :title, String
          end
        end
      end

      specify { expect(User.reflect_on_association(:projects).klass).to eq(User::Project) }
      specify { expect(User.new.projects).to eq([]) }
      specify { expect(User.new.tap { |u| u.projects.create(title: 'Project') }.projects).to be_a(ActiveData::Model::Associations::Collection::Embedded) }
      specify { expect(User.new.tap { |u| u.projects.create(title: 'Project') }.read_attribute(:projects)).to eq([{'title' => 'Project'}]) }
    end

    context do
      before do
        stub_model(:user) do
          include ActiveData::Model::Associations

          attribute :title, String
          embeds_many :projects, class_name: 'Project' do
            attribute :value, String
          end
        end
      end

      specify { expect(User.reflect_on_association(:projects).klass).to eq(User::Project) }
      specify { expect(User.new.projects).to eq([]) }
      specify { expect(User.new.tap { |u| u.projects.create(title: 'Project') }.projects).to be_a(ActiveData::Model::Associations::Collection::Embedded) }
      specify { expect(User.new.tap { |u| u.projects.create(title: 'Project') }.read_attribute(:projects)).to eq([{'title' => 'Project', 'value' => nil}]) }
    end
  end
end

# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations do
  context 'inheritance' do
    before do
      stub_model(:nobody) do
        include ActiveData::Model::Associations
      end
      stub_model(:project) do
        include ActiveData::Model::Associations
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

    specify { expect(Nobody.reflections.keys).to eq([]) }
    specify { expect(User.reflections.keys).to eq([:projects]) }
    specify { expect(Manager.reflections.keys).to eq([:managed_project]) }
    specify { expect(Admin.reflections.keys).to eq([:projects, :admin_projects]) }
  end

  describe '.embeds_one' do
    before do
      stub_model(:author) do
        include ActiveData::Model::Associations
        attribute :name
      end

      stub_model(:book) do
        include ActiveData::Model::Associations
        attribute :title
        embeds_one :author
      end
    end
    let(:book) { Book.new }

    specify { expect(book.author).to be_nil }

    context ':read, :write' do
      before do
        stub_model(:book) do
          include ActiveData::Model::Associations
          attribute :title
          embeds_one :author,
            read: ->(reflection, object) {
              value = object.read_attribute(reflection.name)
              JSON.parse(value) if value.present?
            },
            write: ->(reflection, object, value) {
              object.write_attribute(reflection.name, value ? value.to_json : nil)
            }
        end
      end

      let(:book) { Book.instantiate author: {name: 'Duke'}.to_json }
      let(:author) { Author.new(name: 'Rick') }

      specify { expect { book.author = author }
        .to change { book.read_attribute(:author) }
        .from({name: 'Duke'}.to_json).to({name: 'Rick'}.to_json) }
    end

    describe '#author=' do
      let(:author) { Author.new name: 'Author' }
      specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
      specify { expect { book.author = 'string' }.to raise_error ActiveData::AssociationTypeMismatch }

      context do
        let(:other) { Author.new name: 'Other' }
        before { book.author = other }
        specify { expect { book.author = author }.to change { book.author }.from(other).to(author) }
        specify { expect { book.author = nil }.to change { book.author }.from(other).to(nil) }
      end
    end

    describe '#build_author' do
      let(:author) { Author.new name: 'Author' }
      specify { expect(book.build_author(name: 'Author')).to eq(author) }
      specify { expect { book.build_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
    end

    describe '#create_author' do
      let(:author) { Author.new name: 'Author' }
      specify { expect(book.create_author(name: 'Author')).to eq(author) }
      specify { expect { book.create_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
    end

    describe '#create_author!' do
      let(:author) { Author.new name: 'Author' }
      specify { expect(book.create_author!(name: 'Author')).to eq(author) }
      specify { expect { book.create_author!(name: 'Author') }.to change { book.author }.from(nil).to(author) }
    end

    describe '#==' do
      let(:author) { Author.new name: 'Author' }
      let(:other) { Author.new name: 'Other' }

      specify { expect(Book.new(author: author)).to eq(Book.new(author: author)) }
      specify { expect(Book.new(author: author)).not_to eq(Book.new(author: other)) }
      specify { expect(Book.new(author: author)).not_to eq(Book.new) }
    end
  end

  describe '.embeds_many' do
    before do
      stub_model(:project) do
        include ActiveData::Model::Associations
        attribute :title
      end
      stub_model(:user) do
        include ActiveData::Model::Associations

        attribute :name
        embeds_many :projects
        define_save { true }
      end
    end
    let(:user) { User.new }

    context ':read, :write' do
      before do
        stub_model(:user) do
          include ActiveData::Model::Associations

          attribute :name
          embeds_many :projects,
            read: ->(reflection, object) {
              value = object.read_attribute(reflection.name)
              JSON.parse(value) if value.present?
            },
            write: ->(reflection, object, value) {
              object.write_attribute(reflection.name, value.to_json)
            }
        end
      end

      let(:user) { User.instantiate name: 'Rick', projects: [{title: 'Genesis'}].to_json }
      let(:new_project1) { Project.new(title: 'Project 1') }
      let(:new_project2) { Project.new(title: 'Project 2') }

      specify { expect { user.projects.concat([new_project1, new_project2]) }
        .to change { user.read_attribute(:projects) }
        .from([{title: 'Genesis'}].to_json)
        .to([{title: 'Genesis'}, {title: 'Project 1'}, {title: 'Project 2'}].to_json) }
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
        before { user.update(projects: [project]) }
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

    describe '#==' do
      let(:project) { Project.new title: 'Project' }
      let(:other) { Project.new title: 'Other' }

      specify { expect(User.new(projects: [project])).to eq(User.new(projects: [project])) }
      specify { expect(User.new(projects: [project])).not_to eq(User.new(projects: [other])) }
      specify { expect(User.new(projects: [project])).not_to eq(User.new) }
    end
  end
end

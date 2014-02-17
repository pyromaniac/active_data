# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations do
  context 'inheritance' do
    before do
      stub_model(:nobody)
      stub_model(:project)
      stub_model(:user, Nobody) { embeds_many :projects }
      stub_model(:manager, Nobody) { embeds_one :managed_project, class_name: 'Project' }
      stub_model(:admin, User) { embeds_many :admin_projects, class_name: 'Project' }
    end

    specify { Nobody.reflections.keys.should == [] }
    specify { User.reflections.keys.should == [:projects] }
    specify { Manager.reflections.keys.should == [:managed_project] }
    specify { Admin.reflections.keys.should == [:projects, :admin_projects] }
  end

  context '.embeds_one' do
    before do
      stub_model(:author) do
        attribute :name
      end

      stub_model(:book) do
        attribute :title
        embeds_one :author
      end
    end
    let(:book) { Book.new }

    specify { book.author.should be_nil }

    context ':read, :write' do
      before do
        stub_model(:book) do
          attribute :title
          embeds_one :author,
            read: ->(reflection, object) {
              value = object.read_attribute(reflection.name)
              JSON.parse(value) if value.present?
            },
            write: ->(reflection, object, value) {
              object.write_attribute(reflection.name, value.to_json)
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
      specify { book.build_author(name: 'Author').should == author }
      specify { expect { book.build_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
    end

    describe '#create_author' do
      let(:author) { Author.new name: 'Author' }
      specify { book.create_author(name: 'Author').should == author }
      specify { expect { book.create_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
    end

    describe '#create_author!' do
      let(:author) { Author.new name: 'Author' }
      specify { book.create_author!(name: 'Author').should == author }
      specify { expect { book.create_author!(name: 'Author') }.to change { book.author }.from(nil).to(author) }
    end

    describe '#==' do
      let(:author) { Author.new name: 'Author' }
      let(:other) { Author.new name: 'Other' }

      specify { Book.new(author: author).should == Book.new(author: author) }
      specify { Book.new(author: author).should_not == Book.new(author: other) }
      specify { Book.new(author: author).should_not == Book.new }
    end
  end

  describe '.embeds_many' do
    before do
      stub_model(:project) do
        attribute :title
      end
      stub_model(:user) do
        attribute :name
        embeds_many :projects
      end
    end
    let(:user) { User.new }

    context ':read, :write' do
      before do
        stub_model(:user) do
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
      specify { user.projects.should == [] }

      describe '#build' do
        let(:project) { Project.new title: 'Project' }
        specify { user.projects.build(title: 'Project').should == project }
        specify { expect { user.projects.build(title: 'Project') }.to change { user.projects }.from([]).to([project]) }
        specify { expect { user.projects.build(title: 'Project') }.not_to change { user.projects.reload }.from([]) }
      end

      describe '#create' do
        let(:project) { Project.new title: 'Project' }
        specify { user.projects.create(title: 'Project').should == project }
        specify { expect { user.projects.create(title: 'Project') }.to change { user.projects.reload }.from([]).to([project]) }
      end

      describe '#create!' do
        let(:project) { Project.new title: 'Project' }
        specify { user.projects.create!(title: 'Project').should == project }
        specify { expect { user.projects.create!(title: 'Project') }.to change { user.projects.reload }.from([]).to([project]) }
      end

      describe '#reload' do
        let(:project) { Project.new title: 'Project' }
        before { user.projects = [project] }
        before { user.projects.build }

        specify { user.projects.count.should == 2 }
        specify { user.projects.reload.should == [project] }
      end

      describe '#concat' do
        let(:project) { Project.new title: 'Project' }
        specify { expect { user.projects.concat project }.to change { user.projects.reload }.from([]).to([project]) }
        specify { expect { user.projects.concat project, 'string' }.to raise_error ActiveData::AssociationTypeMismatch }

        context do
          let(:other) { Project.new title: 'Other' }
          before { user.projects = [other] }
          specify { expect { user.projects.concat project }.to change { user.projects.reload }.from([other]).to([other, project]) }
        end
      end
    end

    describe '#projects=' do
      let(:project) { Project.new title: 'Project' }
      specify { expect { user.projects = [] }.not_to change { user.projects.reload }.from([]) }
      specify { expect { user.projects = [project] }.to change { user.projects.reload }.from([]).to([project]) }
      specify { expect { user.projects = [project, 'string'] }.to raise_error ActiveData::AssociationTypeMismatch }

      context do
        let(:other) { Project.new title: 'Other' }
        before { user.projects = [other] }
        specify { expect { user.projects = [project] }.to change { user.projects.reload }.from([other]).to([project]) }
        specify { expect { user.projects = [] }.to change { user.projects.reload }.from([other]).to([]) }
      end
    end

    describe '#==' do
      let(:project) { Project.new title: 'Project' }
      let(:other) { Project.new title: 'Other' }

      specify { User.new(projects: [project]).should == User.new(projects: [project]) }
      specify { User.new(projects: [project]).should_not == User.new(projects: [other]) }
      specify { User.new(projects: [project]).should_not == User.new }
    end
  end
end

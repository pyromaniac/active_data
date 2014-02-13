# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::Reflections::EmbedsMany do
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

  specify { user.projects.should == [] }

  describe '#association' do
    specify { user.association(:projects).should be_a ActiveData::Model::Associations::Builders::EmbedsMany }
    specify { user.association(:projects).should == user.association(:projects) }
  end

  describe '#projects' do
    let(:project) { Project.new title: 'Project' }
    specify { user.projects.build(title: 'Project').should == project }
    specify { expect { user.projects.build(title: 'Project') }.to change { user.projects }.from([]).to([project]) }
  end

  describe '#projects=' do
    let(:project) { Project.new title: 'Project' }
    specify { expect { user.projects = nil }.not_to change { user.projects }.from([]) }
    specify { expect { user.projects = [] }.not_to change { user.projects }.from([]) }
    specify { expect { user.projects = [project] }.to change { user.projects }.from([]).to([project]) }
    specify { expect { user.projects = [project, 'string'] }.to raise_error ActiveData::IncorrectEntity }

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

    specify { User.new(projects: [project]).should == User.new(projects: [project]) }
    specify { User.new(projects: [project]).should_not == User.new(projects: [other]) }
    specify { User.new(projects: [project]).should_not == User.new }
  end
end

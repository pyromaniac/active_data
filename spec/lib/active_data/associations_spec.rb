# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Associations do
  context 'inheritance' do
    before do
      stub_model(:nobody)
      stub_model(:user, Nobody) { embeds_many :projects }
      stub_model(:manager, Nobody) { embeds_one :managed_project }
      stub_model(:admin, User) { embeds_many :admin_projects }
    end

    specify { Nobody.reflections.keys.should == [] }
    specify { User.reflections.keys.should == [:projects] }
    specify { Manager.reflections.keys.should == [:managed_project] }
    specify { Admin.reflections.keys.should == [:projects, :admin_projects] }
  end
end

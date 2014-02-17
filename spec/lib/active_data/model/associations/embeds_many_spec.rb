# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsMany do
  before do
    stub_model(:dummy)
    stub_model(:project) do
      include ActiveData::Model::Callbacks
      attribute :title
      validates :title, presence: true
    end
    stub_model(:user) do
      attribute :name
      embeds_many :projects
    end
  end

  let(:user) { User.new }
  let(:association) { user.association(:projects) }

  let(:existing_user) { User.instantiate name: 'Rick', projects: [{title: 'Genesis'}] }
  let(:existing_association) { existing_user.association(:projects) }

  describe 'user#association' do
    specify { association.should be_a described_class }
    specify { association.should == user.association(:projects) }
  end

  describe '#build' do
    specify { association.build.should be_a Project }
    specify { association.build.should_not be_persisted }

    specify { expect { association.build(title: 'Swordfish') }
      .not_to change { user.read_attribute(:projects) } }
    specify { expect { association.build(title: 'Swordfish') }
      .to change { association.reader.map(&:attributes) }
      .from([]).to([{'title' => 'Swordfish'}]) }

    specify { expect { existing_association.build(title: 'Swordfish') }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.build(title: 'Swordfish') }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]) }
  end

  describe '#create' do
    specify { association.create.should be_a Project }
    specify { association.create.should_not be_persisted }

    specify { association.create(title: 'Swordfish').should be_a Project }
    specify { association.create(title: 'Swordfish').should be_persisted }

    specify { expect { association.create }
      .not_to change { user.read_attribute(:projects) } }
    specify { expect { association.create(title: 'Swordfish') }
      .to change { user.read_attribute(:projects) }.from(nil).to([{'title' => 'Swordfish'}]) }
    specify { expect { association.create(title: 'Swordfish') }
      .to change { association.reader.map(&:attributes) }
      .from([]).to([{'title' => 'Swordfish'}]) }

    specify { expect { existing_association.create }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.create(title: 'Swordfish') }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{title: 'Genesis'}, {'title' => 'Swordfish'}]) }
    specify { expect { existing_association.create(title: 'Swordfish') }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]) }
  end

  describe '#create!' do
    specify { expect { association.create! }.to raise_error ActiveData::ValidationError }

    specify { association.create!(title: 'Swordfish').should be_a Project }
    specify { association.create!(title: 'Swordfish').should be_persisted }

    specify { expect { association.create! rescue nil }
      .not_to change { user.read_attribute(:projects) } }
    specify { expect { association.create! rescue nil }
      .to change { association.reader.map(&:attributes) }.from([]).to([{'title' => nil}]) }
    specify { expect { association.create!(title: 'Swordfish') }
      .to change { user.read_attribute(:projects) }.from(nil).to([{'title' => 'Swordfish'}]) }
    specify { expect { association.create!(title: 'Swordfish') }
      .to change { association.reader.map(&:attributes) }
      .from([]).to([{'title' => 'Swordfish'}]) }

    specify { expect { existing_association.create! rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.create! rescue nil }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => nil}]) }
    specify { expect { existing_association.create!(title: 'Swordfish') }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{title: 'Genesis'}, {'title' => 'Swordfish'}]) }
    specify { expect { existing_association.create!(title: 'Swordfish') }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]) }
  end

  describe '#reload' do
    specify { association.reload.should == [] }

    specify { existing_association.reload.should == existing_user.projects }

    context do
      before { association.build(title: 'Swordfish') }
      specify { expect { association.reload }
        .to change { association.reader.map(&:attributes) }.from([{'title' => 'Swordfish'}]).to([]) }
    end

    context do
      before { existing_association.build(title: 'Swordfish') }
      specify { expect { existing_association.reload }
        .to change { existing_association.reader.map(&:attributes) }
        .from([{'title' => 'Genesis'}, {'title' => 'Swordfish'}]).to([{'title' => 'Genesis'}]) }
    end
  end

  describe '#clear' do
    specify { association.clear.should == true }
    specify { expect { association.clear }.not_to change { association.reader } }

    specify { existing_association.clear.should == true }
    specify { expect { existing_association.clear }
      .to change { existing_association.reader.map(&:attributes) }.from([{'title' => 'Genesis'}]).to([]) }
    specify { expect { existing_association.clear }
      .to change { existing_user.read_attribute(:projects) }.from([{title: 'Genesis'}]).to([]) }

    context do
      let(:existing_user) { User.instantiate name: 'Rick', projects: [{title: 'Genesis'}, {title: 'Swordfish'}] }
      before { Project.before_destroy { title == 'Genesis' } }

      specify { existing_association.clear.should == false }
      specify { expect { existing_association.clear }
        .not_to change { existing_association.reader } }
      specify { expect { existing_association.clear }
        .not_to change { existing_user.read_attribute(:projects) } }
    end
  end

  describe '#reader' do
    specify { association.reader.should == [] }

    specify { existing_association.reader.first.should be_a Project }
    specify { existing_association.reader.first.should be_persisted }

    context do
      before { association.build }
      specify { association.reader.last.should be_a Project }
      specify { association.reader.last.should_not be_persisted }
      specify { association.reader.size.should == 1 }
      specify { association.reader(true).should == [] }
    end

    context do
      before { existing_association.build(title: 'Swordfish') }
      specify { existing_association.reader.size.should == 2 }
      specify { existing_association.reader.last.title.should == 'Swordfish' }
      specify { existing_association.reader(true).size.should == 1 }
      specify { existing_association.reader(true).last.title.should == 'Genesis' }
    end
  end

  describe '#writer' do
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }
    let(:invalid_project) { Project.new }

    specify { expect { association.writer([Dummy.new]) }
      .to raise_error ActiveData::AssociationTypeMismatch }

    specify { expect { association.writer(nil) }.to raise_error }
    specify { expect { association.writer(new_project1) }.to raise_error }
    specify { association.writer([]).should == [] }

    specify { association.writer([new_project1]).should == [new_project1] }
    specify { expect { association.writer([new_project1]) }
      .to change { association.reader.map(&:attributes) }.from([]).to([{'title' => 'Project 1'}]) }
    specify { expect { association.writer([new_project1]) }
      .to change { user.read_attribute(:projects) }.from(nil).to([{'title' => 'Project 1'}]) }

    specify { expect { existing_association.writer([new_project1, invalid_project]) }
      .to raise_error ActiveData::AssociationNotSaved }
    specify { expect { existing_association.writer([new_project1, invalid_project]) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.writer([new_project1, invalid_project]) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect { existing_association.writer([new_project1, Dummy.new, new_project2]) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { existing_association.writer([new_project1, Dummy.new, new_project2]) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.writer([new_project1, Dummy.new, new_project2]) rescue nil }
      .not_to change { existing_association.reader } }

    specify { expect { existing_association.writer(nil) }.to raise_error }
    specify { expect { existing_association.writer(nil) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.writer(nil) rescue nil }
      .not_to change { existing_association.reader } }

    specify { existing_association.writer([]).should == [] }
    specify { expect { existing_association.writer([]) }
      .to change { existing_user.read_attribute(:projects) }.to([]) }
    specify { expect { existing_association.writer([]) }
      .to change { existing_association.reader }.to([]) }

    specify { existing_association.writer([new_project1, new_project2]).should == [new_project1, new_project2] }
    specify { expect { existing_association.writer([new_project1, new_project2]) }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
    specify { expect { existing_association.writer([new_project1, new_project2]) }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
  end

  describe '#concat' do
    let(:new_project1) { Project.new(title: 'Project 1') }
    let(:new_project2) { Project.new(title: 'Project 2') }
    let(:invalid_project) { Project.new }

    specify { expect { association.concat(Dummy.new) }
      .to raise_error ActiveData::AssociationTypeMismatch }

    specify { expect { association.concat(nil) }.to raise_error }
    specify { association.concat([]).should == [] }
    specify { existing_association.concat([]).should == existing_user.projects }
    specify { existing_association.concat.should == existing_user.projects }

    specify { association.concat(new_project1).should == [new_project1] }
    specify { expect { association.concat(new_project1) }
      .to change { association.reader.map(&:attributes) }.from([]).to([{'title' => 'Project 1'}]) }
    specify { expect { association.concat(new_project1) }
      .to change { user.read_attribute(:projects) }.from(nil).to([{'title' => 'Project 1'}]) }

    specify { existing_association.concat(new_project1, invalid_project).should == false }
    specify { expect { existing_association.concat(new_project1, invalid_project) }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: "Genesis"}]).to([{title: 'Genesis'}, {'title' => 'Project 1'}]) }
    specify { expect { existing_association.concat(new_project1, invalid_project) }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}, {'title' => nil}]) }

    specify { expect { existing_association.concat(new_project1, Dummy.new, new_project2) }
      .to raise_error ActiveData::AssociationTypeMismatch }
    specify { expect { existing_association.concat(new_project1, Dummy.new, new_project2) rescue nil }
      .not_to change { existing_user.read_attribute(:projects) } }
    specify { expect { existing_association.concat(new_project1, Dummy.new, new_project2) rescue nil }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}]) }

    specify { existing_association.concat(new_project1, new_project2)
      .should == [existing_user.projects.first, new_project1, new_project2] }
    specify { expect { existing_association.concat([new_project1, new_project2]) }
      .to change { existing_association.reader.map(&:attributes) }
      .from([{'title' => 'Genesis'}]).to([{'title' => 'Genesis'}, {'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
    specify { expect { existing_association.concat([new_project1, new_project2]) }
      .to change { existing_user.read_attribute(:projects) }
      .from([{title: 'Genesis'}]).to([{title: 'Genesis'}, {'title' => 'Project 1'}, {'title' => 'Project 2'}]) }
  end
end

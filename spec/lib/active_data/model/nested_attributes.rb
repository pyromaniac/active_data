require 'spec_helper'

shared_examples 'nested attributes' do
  before do
    stub_model :project do
      include ActiveData::Model::Primary
      include ActiveData::Model::Lifecycle

      primary :slug, String
      attribute :title, String
    end

    stub_model :profile do
      include ActiveData::Model::Primary
      include ActiveData::Model::Lifecycle

      primary :identifier
      attribute :first_name, String
    end
  end

  context 'embeds_one' do
    let(:user) { User.new }

    specify { expect { user.profile_attributes = {} }.to change { user.profile }.to(an_instance_of(Profile)) }
    specify { expect { user.profile_attributes = {first_name: 'User'} }.to change { user.profile.try(:first_name) }.to('User') }
    specify { expect { user.profile_attributes = {identifier: 42, first_name: 'User'} }.to raise_error ActiveData::ObjectNotFound }

    context ':reject_if' do
      context do
        before { User.accepts_nested_attributes_for :profile, reject_if: :all_blank }
        specify { expect { user.profile_attributes = {first_name: ''} }.not_to change { user.profile } }
      end

      context do
        before { User.accepts_nested_attributes_for :profile, reject_if: ->(attributes) { attributes['first_name'].blank? } }
        specify { expect { user.profile_attributes = {first_name: ''} }.not_to change { user.profile } }
      end
    end

    context 'existing' do
      let(:profile) { Profile.new(first_name: 'User') }
      let(:user) { User.new profile: profile }

      specify { expect { user.profile_attributes = {identifier: 42, first_name: 'User'} }.to raise_error ActiveData::ObjectNotFound }
      specify { expect { user.profile_attributes = {identifier: profile.identifier.to_s, first_name: 'User 1'} }.to change { user.profile.first_name }.to('User 1') }
      specify { expect { user.profile_attributes = {first_name: 'User 1'} }.to change { user.profile.first_name }.to('User 1') }
      specify { expect { user.profile_attributes = {first_name: 'User 1', _destroy: '1'} }.not_to change { user.profile.first_name } }
      specify { expect { user.profile_attributes = {first_name: 'User 1', _destroy: '1'}; user.save { true } }.not_to change { user.profile.first_name } }
      specify { expect { user.profile_attributes = {identifier: profile.identifier.to_s, first_name: 'User 1', _destroy: '1'} }.to change { user.profile.first_name }.to('User 1') }
      specify { expect { user.profile_attributes = {identifier: profile.identifier.to_s, first_name: 'User 1', _destroy: '1'}; user.save { true } }.to change { user.profile.first_name }.to('User 1') }

      context ':allow_destroy' do
        before { User.accepts_nested_attributes_for :profile, allow_destroy: true }

        specify { expect { user.profile_attributes = {first_name: 'User 1', _destroy: '1'} }.not_to change { user.profile.first_name } }
        specify { expect { user.profile_attributes = {first_name: 'User 1', _destroy: '1'}; user.save { true } }.not_to change { user.profile.first_name } }
        specify { expect { user.profile_attributes = {identifier: profile.identifier.to_s, first_name: 'User 1', _destroy: '1'} }.to change { user.profile.first_name }.to('User 1') }
        specify { expect { user.profile_attributes = {identifier: profile.identifier.to_s, first_name: 'User 1', _destroy: '1'}; user.save { true } }.to change { user.profile }.to(nil) }
      end

      context ':update_only' do
        before { User.accepts_nested_attributes_for :profile, update_only: true }

        specify { expect { user.profile_attributes = {identifier: 42, first_name: 'User 1'} }.to change { user.profile.first_name }.to('User 1') }
      end
    end
  end

  context 'embeds_many' do
    let(:user) { User.new }

    specify { expect { user.projects_attributes = {} }.not_to change { user.projects } }
    specify { expect { user.projects_attributes = [{title: 'Project 1'}, {title: 'Project 2'}] }
      .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 2']) }
    specify { expect { user.projects_attributes = {1 => {title: 'Project 1'}, 2 => {title: 'Project 2'}} }
      .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 2']) }
    specify { expect { user.projects_attributes = [{slug: 42, title: 'Project 1'}, {title: 'Project 2'}] }
      .to change { user.projects.map(&:title) }.to(['Project 1', 'Project 2']) }
    specify { expect { user.projects_attributes = [{title: ''}, {title: 'Project 2'}] }
      .to change { user.projects.map(&:title) }.to(['', 'Project 2']) }

    context ':limit' do
      before { User.accepts_nested_attributes_for :projects, limit: 1 }

      specify { expect { user.projects_attributes = [{title: 'Project 1'}] }
        .to change { user.projects.map(&:title) }.to(['Project 1']) }
      specify { expect { user.projects_attributes = [{title: 'Project 1'}, {title: 'Project 2'}] }
        .to raise_error ActiveData::TooManyObjects }
    end

    context ':reject_if' do
      context do
        before { User.accepts_nested_attributes_for :projects, reject_if: :all_blank }
        specify { expect { user.projects_attributes = [{title: ''}, {title: 'Project 2'}] }
          .to change { user.projects.map(&:title) }.to(['Project 2']) }
      end

      context do
        before { User.accepts_nested_attributes_for :projects, reject_if: ->(attributes) { attributes['title'].blank? } }
        specify { expect { user.projects_attributes = [{title: ''}, {title: 'Project 2'}] }
          .to change { user.projects.map(&:title) }.to(['Project 2']) }
      end

      context do
        before { User.accepts_nested_attributes_for :projects, reject_if: ->(attributes) { attributes['foobar'].blank? } }
        specify { expect { user.projects_attributes = [{title: ''}, {title: 'Project 2'}] }
          .not_to change { user.projects } }
      end
    end

    context 'existing' do
      let(:projects) { 2.times.map { |i| Project.new(title: "Project #{i.next}").tap { |pr| pr.slug = 42+i } } }
      let(:user) { User.new projects: projects }

      specify { expect { user.projects_attributes = [
          {slug: projects.first.slug.to_i, title: 'Project 3'},
          {title: 'Project 4'}
        ] }
        .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2', 'Project 4']) }
      specify { expect { user.projects_attributes = [
          {slug: projects.first.slug.to_i, title: 'Project 3'},
          {slug: 33, title: 'Project 4'}
        ] }
        .to change { user.projects.map(&:slug) }.to(['42', '43', '33']) }
      specify { expect { user.projects_attributes = {
          1 => {slug: projects.first.slug.to_i, title: 'Project 3'},
          2 => {title: 'Project 4'}
        } }
        .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2', 'Project 4']) }
      specify { expect { user.projects_attributes = [
          {slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1'},
          {title: 'Project 4', _destroy: '1'}
        ] }
        .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2']) }
      specify { expect { user.projects_attributes = [
          {slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1'},
          {title: 'Project 4', _destroy: '1'}
        ]
        user.save { true } }
        .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2']) }

      context ':allow_destroy' do
        before { User.accepts_nested_attributes_for :projects, allow_destroy: true }

        specify { expect { user.projects_attributes = [
            {slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1'},
            {title: 'Project 4', _destroy: '1'}
          ] }
          .to change { user.projects.map(&:title) }.to(['Project 3', 'Project 2']) }
        specify { expect { user.projects_attributes = [
            {slug: projects.first.slug.to_i, title: 'Project 3', _destroy: '1'},
            {title: 'Project 4', _destroy: '1'}
          ]
          user.save { true } }
          .to change { user.projects.map(&:title) }.to(['Project 2']) }
      end
    end
  end
end

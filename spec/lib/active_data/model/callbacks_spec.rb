# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Lifecycle do
  before do
    stub_model(:user) do
      include ActiveData::Model::Callbacks

      attribute :actions, type: Array, default: []

      def append action
        self.actions = actions + [action]
      end

      define_create { append :create }
      define_update { append :update }
      define_destroy { append :destroy }
    end
  end

  describe '.after_initialize' do
    before do
      User.after_initialize { append :after_initialize }
    end

    specify { User.new.actions.should == [:after_initialize] }
    specify { User.create.actions.should == [:after_initialize, :create] }
  end

  describe '.before_save, .after_save' do
    before do
      User.before_save { append :before_save }
      User.after_save { append :after_save }
    end

    specify { User.create.actions.should == [:before_save, :create, :after_save] }
    specify { User.new.tap(&:save).actions.should == [:before_save, :create, :after_save] }
    specify { User.new.tap{ |u| u.update({}) }.actions.should == [:before_save, :create, :after_save] }
    specify { User.create.tap(&:save).actions.should == [:before_save, :create, :after_save, :before_save, :update, :after_save] }
    specify { User.create.tap{ |u| u.update({}) }.actions.should == [:before_save, :create, :after_save, :before_save, :update, :after_save] }
  end

  describe '.around_save' do
    before do
      User.around_save do |&block|
        append :before_around_save
        block.call
        append :after_around_save
      end
    end

    specify { User.create.actions.should == [:before_around_save, :create, :after_around_save] }
    specify { User.new.tap(&:save).actions.should == [:before_around_save, :create, :after_around_save] }
    specify { User.new.tap{ |u| u.update({}) }.actions.should == [:before_around_save, :create, :after_around_save] }
    specify { User.create.tap(&:save).actions.should == [:before_around_save, :create, :after_around_save, :before_around_save, :update, :after_around_save] }
    specify { User.create.tap{ |u| u.update({}) }.actions.should == [:before_around_save, :create, :after_around_save, :before_around_save, :update, :after_around_save] }
  end

  describe '.before_create, .after_create' do
    before do
      User.before_create { append :before_create }
      User.after_create { append :after_create }
    end

    specify { User.create.actions.should == [:before_create, :create, :after_create] }
    specify { User.new.tap(&:save).actions.should == [:before_create, :create, :after_create] }
    specify { User.new.tap{ |u| u.update({}) }.actions.should == [:before_create, :create, :after_create] }
    specify { User.create.tap(&:save).actions.should == [:before_create, :create, :after_create, :update] }
    specify { User.create.tap{ |u| u.update({}) }.actions.should == [:before_create, :create, :after_create, :update] }
  end

  describe '.around_create' do
    before do
      User.around_create do |&block|
        append :before_around_create
        block.call
        append :after_around_create
      end
    end

    specify { User.create.actions.should == [:before_around_create, :create, :after_around_create] }
    specify { User.new.tap(&:save).actions.should == [:before_around_create, :create, :after_around_create] }
    specify { User.new.tap{ |u| u.update({}) }.actions.should == [:before_around_create, :create, :after_around_create] }
    specify { User.create.tap(&:save).actions.should == [:before_around_create, :create, :after_around_create, :update] }
    specify { User.create.tap{ |u| u.update({}) }.actions.should == [:before_around_create, :create, :after_around_create, :update] }
  end

  describe '.before_update, .after_update' do
    before do
      User.before_update { append :before_update }
      User.after_update { append :after_update }
    end

    specify { User.create.actions.should == [:create] }
    specify { User.new.tap(&:save).actions.should == [:create] }
    specify { User.new.tap{ |u| u.update({}) }.actions.should == [:create] }
    specify { User.create.tap(&:save).actions.should == [:create, :before_update, :update, :after_update] }
    specify { User.create.tap{ |u| u.update({}) }.actions.should == [:create, :before_update, :update, :after_update] }
  end

  describe '.around_update' do
    before do
      User.around_update do |&block|
        append :before_around_update
        block.call
        append :after_around_update
      end
    end

    specify { User.create.actions.should == [:create] }
    specify { User.new.tap(&:save).actions.should == [:create] }
    specify { User.new.tap{ |u| u.update({}) }.actions.should == [:create] }
    specify { User.create.tap(&:save).actions.should == [:create, :before_around_update, :update, :after_around_update] }
    specify { User.create.tap{ |u| u.update({}) }.actions.should == [:create, :before_around_update, :update, :after_around_update] }
  end

  describe '.before_save, .after_save, .around_save, .before_create, .after_create, .around_create, .before_update, .after_update, .around_update' do
    before do
      User.before_save { append :before_save }
      User.after_save { append :after_save }
      User.around_save do |&block|
        append :before_around_save
        block.call
        append :after_around_save
      end
      User.before_create { append :before_create }
      User.after_create { append :after_create }
      User.around_create do |&block|
        append :before_around_create
        block.call
        append :after_around_create
      end
      User.before_update { append :before_update }
      User.after_update { append :after_update }
      User.around_update do |&block|
        append :before_around_update
        block.call
        append :after_around_update
      end
    end

    specify { User.create.tap(&:save).actions.should == [
      :before_save, :before_around_save,
      :before_create, :before_around_create,
      :create,
      :after_around_create, :after_create,
      :after_around_save, :after_save,

      :before_save, :before_around_save,
      :before_update, :before_around_update,
      :update,
      :after_around_update, :after_update,
      :after_around_save, :after_save
    ] }
  end

  describe '.before_destroy, .after_destroy' do
    before do
      User.before_destroy { append :before_destroy }
      User.after_destroy { append :after_destroy }
    end

    specify { User.new.destroy.actions.should == [:before_destroy, :destroy, :after_destroy] }
    specify { User.create.destroy.actions.should == [:create, :before_destroy, :destroy, :after_destroy] }
  end

  describe '.around_destroy' do
    before do
      User.around_destroy do |&block|
        append :before_around_destroy
        block.call
        append :after_around_destroy
      end
    end

    specify { User.new.destroy.actions.should == [:before_around_destroy, :destroy, :after_around_destroy] }
    specify { User.create.destroy.actions.should == [:create, :before_around_destroy, :destroy, :after_around_destroy] }
  end
end
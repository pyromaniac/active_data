# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Lifecycle do
  context do
    before do
      stub_model(:user) do
        include ActiveData::Model::Lifecycle
      end
    end

    subject { User.new }

    specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
    specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }

    specify { expect { subject.destroy }.to raise_error ActiveData::UndestroyableObject }
    specify { expect { subject.destroy! }.to raise_error ActiveData::UndestroyableObject }

    context do
      before { User.define_create { true } }

      specify { subject.save.should == true }
      specify { subject.save!.should == true }

      context do
        subject { User.create }

        specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
        specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }
      end
    end

    context do
      before { User.define_update { true } }

      specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
      specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }
    end
  end

  context do
    before do
      stub_class(:storage) do
        def self.storage
          @storage ||= {}
        end
      end
    end

    before do
      stub_model(:user) do
        include ActiveData::Model::Lifecycle
        delegate :generate_id, to: 'self.class'

        attribute :id, type: Integer, &:generate_id
        attribute :name
        validates :id, :name, presence: true

        def self.generate_id
          @id = @id.to_i.next
        end

        define_save do
          Storage.storage.merge!(id => attributes.symbolize_keys)
        end

        define_destroy do
          Storage.storage.delete(id)
        end
      end
    end

    describe '.create' do
      subject { User.create(name: 'Jonny') }

      it { should be_a User }
      it { should be_valid }
      it { should be_persisted }

      context 'invalid' do
        subject { User.create }

        it { should be_a User }
        it { should be_invalid }
        it { should_not be_persisted }
      end
    end

    describe '.create!' do
      subject { User.create!(name: 'Jonny') }

      it { should be_a User }
      it { should be_valid }
      it { should be_persisted }

      context 'invalid' do
        subject { User.create! }

        specify { expect { subject }.to raise_error ActiveData::ValidationError }
      end
    end

    describe '#update, #update!' do
      subject { User.new }

      specify { expect { subject.update(name: 'Jonny') }.to change { subject.persisted? }.from(false).to(true) }
      specify { expect { subject.update!(name: 'Jonny') }.to change { subject.persisted? }.from(false).to(true) }

      specify { expect { subject.update({}) }.not_to change { subject.persisted? } }
      specify { expect { subject.update!({}) }.to raise_error ActiveData::ValidationError }

      specify { expect { subject.update(name: 'Jonny') }
        .to change { Storage.storage.keys }.from([]).to([subject.id]) }
      specify { expect { subject.update!(name: 'Jonny') }
        .to change { Storage.storage.keys }.from([]).to([subject.id]) }

      specify { expect { subject.update(name: 'Jonny') { Storage.storage[id] = 'created' } }
        .to change { Storage.storage[subject.id] }.from(nil).to('created') }
      specify { expect { subject.update!(name: 'Jonny') { Storage.storage[id] = 'created' } }
        .to change { Storage.storage[subject.id] }.from(nil).to('created') }
    end

    describe '#update_attributes, #update_attributes!' do
      subject { User.new }

      specify { expect { subject.update_attributes(name: 'Jonny') }.to change { subject.persisted? }.from(false).to(true) }
      specify { expect { subject.update_attributes!(name: 'Jonny') }.to change { subject.persisted? }.from(false).to(true) }

      specify { expect { subject.update_attributes({}) }.not_to change { subject.persisted? } }
      specify { expect { subject.update_attributes!({}) }.to raise_error ActiveData::ValidationError }

      specify { expect { subject.update_attributes(name: 'Jonny') }
        .to change { Storage.storage.keys }.from([]).to([subject.id]) }
      specify { expect { subject.update_attributes!(name: 'Jonny') }
        .to change { Storage.storage.keys }.from([]).to([subject.id]) }

      specify { expect { subject.update_attributes(name: 'Jonny') { Storage.storage[id] = 'created' } }
        .to change { Storage.storage[subject.id] }.from(nil).to('created') }
      specify { expect { subject.update_attributes!(name: 'Jonny') { Storage.storage[id] = 'created' } }
        .to change { Storage.storage[subject.id] }.from(nil).to('created') }
    end

    describe '#save, #save!' do
      context 'invalid' do
        subject { User.new }

        it { should be_invalid }
        it { should_not be_persisted }

        specify { subject.save.should be_false }
        specify { expect { subject.save! }.to raise_error ActiveData::ValidationError }

        specify { expect { subject.save }.not_to change { subject.persisted? } }
        specify { expect { subject.save! rescue nil }.not_to change { subject.persisted? } }
      end

      context 'create' do
        subject { User.new(name: 'Jonny') }

        it { should be_valid }
        it { should_not be_persisted }

        specify { subject.save.should be_true }
        specify { subject.save!.should be_true }

        specify { expect { subject.save }.to change { subject.persisted? }.from(false).to(true) }
        specify { expect { subject.save! }.to change { subject.persisted? }.from(false).to(true) }

        specify { expect { subject.save }.to change { Storage.storage.keys }.from([]).to([subject.id]) }
        specify { expect { subject.save! }.to change { Storage.storage.keys }.from([]).to([subject.id]) }

        specify { expect { subject.save { Storage.storage[id] = 'created' } }
          .to change { Storage.storage[subject.id] }.from(nil).to('created') }
        specify { expect { subject.save! { Storage.storage[id] = 'created' } }
          .to change { Storage.storage[subject.id] }.from(nil).to('created') }

        context 'save failed' do
          before { User.define_save { false } }

          it { should_not be_persisted }

          specify { subject.save.should be_false }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }

          specify { expect { subject.save }.not_to change { subject.persisted? } }
          specify { expect { subject.save! rescue nil }.not_to change { subject.persisted? } }
        end
      end

      context 'update' do
        subject! { User.new(name: 'Jonny').tap(&:save).tap { |u| u.name = 'Jimmy' } }

        it { should be_valid }
        it { should be_persisted }

        specify { subject.save.should be_true }
        specify { subject.save!.should be_true }

        specify { expect { subject.save }.not_to change { subject.persisted? } }
        specify { expect { subject.save! }.not_to change { subject.persisted? } }

        specify { expect { subject.save }.to change { Storage.storage[subject.id] }
          .from(hash_including(name: 'Jonny')).to(hash_including(name: 'Jimmy')) }
        specify { expect { subject.save! }.to change { Storage.storage[subject.id] }
          .from(hash_including(name: 'Jonny')).to(hash_including(name: 'Jimmy')) }

        specify { expect { subject.save { Storage.storage[id] = 'updated' } }
          .to change { Storage.storage[subject.id] }
          .from(hash_including(name: 'Jonny')).to('updated') }
        specify { expect { subject.save! { Storage.storage[id] = 'updated' } }
          .to change { Storage.storage[subject.id] }
          .from(hash_including(name: 'Jonny')).to('updated') }

        context 'save failed' do
          before { User.define_save { false } }

          it { should be_persisted }

          specify { subject.save.should be_false }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }

          specify { expect { subject.save }.not_to change { subject.persisted? } }
          specify { expect { subject.save! rescue nil }.not_to change { subject.persisted? } }
        end
      end
    end

    describe '#destroy, #destroy!' do
      subject { User.create(name: 'Jonny') }

      it { should be_valid }
      it { should be_persisted }
      it { should_not be_destroyed }

      specify { subject.destroy.should == subject }
      specify { subject.destroy!.should == subject }

      specify { expect { subject.destroy }.to change { subject.persisted? }.from(true).to(false) }
      specify { expect { subject.destroy! }.to change { subject.persisted? }.from(true).to(false) }

      specify { expect { subject.destroy }.to change { subject.destroyed? }.from(false).to(true) }
      specify { expect { subject.destroy! }.to change { subject.destroyed? }.from(false).to(true) }

      specify { expect { subject.destroy }.to change { Storage.storage.keys }.from([subject.id]).to([]) }
      specify { expect { subject.destroy! }.to change { Storage.storage.keys }.from([subject.id]).to([]) }

      specify { expect { subject.destroy { Storage.storage[id] = 'deleted' } }
        .to change { Storage.storage[subject.id] }.to('deleted') }
      specify { expect { subject.destroy! { Storage.storage[id] = 'deleted' } }
        .to change { Storage.storage[subject.id] }.to('deleted') }

      context 'save failed' do
        before { User.define_destroy { false } }

        it { should be_persisted }

        specify { subject.destroy.should == subject }
        specify { expect { subject.destroy! }.to raise_error ActiveData::ObjectNotDestroyed }

        specify { expect { subject.destroy }.not_to change { subject.persisted? } }
        specify { expect { subject.destroy! rescue nil }.not_to change { subject.persisted? } }

        specify { expect { subject.destroy }.not_to change { subject.destroyed? } }
        specify { expect { subject.destroy! rescue nil }.not_to change { subject.destroyed? } }
      end
    end
  end
end

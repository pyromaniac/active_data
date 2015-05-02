# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Lifecycle do
  context do
    before do
      stub_model(:user)
    end

    subject { User.new }

    [:save, :create, :update, :destroy].each do |action|
      specify { expect { subject.public_send "_#{action}_performer=", '' }.to raise_error NoMethodError }
    end

    context 'performer execution' do
      let(:foo) { true }

      specify { expect { subject.save { foo } }.to raise_error NameError }
      specify { expect { subject.save { |instance| attributes } }.to raise_error NameError }
      specify { subject.save { attributes }.should == true }
      specify { subject.save { |instance| foo }.should == true }
    end

    context 'save' do
      specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
      specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }

      specify { subject.save { true }.should == true }
      specify { subject.save! { true }.should == true }

      context 'instance performer' do
        before { subject.define_save { false } }

        specify { subject.save.should == false }
        specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
      end

      context 'create performer' do
        before { User.define_create { true } }

        specify { subject.save.should == true }
        specify { subject.save!.should == true }

        context do
          subject { User.create }

          specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
          specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }
        end

        context 'instance performer' do
          before { subject.define_create { false } }

          specify { subject.save.should == false }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
        end
      end

      context 'update performer' do
        before { User.define_update { true } }

        specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
        specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }

        context do
          subject { User.new.tap { |u| u.save { true } } }

          specify { subject.save.should == true }
          specify { subject.save!.should == true }

          context 'instance performer' do
            before { subject.define_update { false } }

            specify { subject.save.should == false }
            specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
          end
        end
      end

      context 'performers execution' do
        before do
          stub_model(:user) do
            attribute :actions, type: Array, default: []

            def append action
              self.actions = actions + [action]
            end

            define_create { append :create }
            define_update { append :update }
            define_destroy { append :destroy }
          end
        end

        subject { User.new }

        specify do
          subject.destroy
          subject.save
          subject.save
          subject.destroy
          subject.destroy
          subject.save
          subject.actions.should == [:destroy, :create, :update, :destroy, :destroy, :create]
        end
      end
    end

    context 'destroy' do
      specify { expect { subject.destroy }.to raise_error ActiveData::UndestroyableObject }
      specify { expect { subject.destroy! }.to raise_error ActiveData::UndestroyableObject }

      specify { subject.destroy { true }.should be_a User }
      specify { subject.destroy! { true }.should be_a User }

      context 'instance performer' do
        before { subject.define_save { false } }

        specify { subject.save.should == false }
        specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
      end
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
    end

    describe '#save, #save!' do
      context 'invalid' do
        subject { User.new }

        it { should be_invalid }
        it { should_not be_persisted }

        specify { subject.save.should == false }
        specify { expect { subject.save! }.to raise_error ActiveData::ValidationError }

        specify { expect { subject.save }.not_to change { subject.persisted? } }
        specify { expect { subject.save! rescue nil }.not_to change { subject.persisted? } }
      end

      context 'create' do
        subject { User.new(name: 'Jonny') }

        it { should be_valid }
        it { should_not be_persisted }

        specify { subject.save.should == true }
        specify { subject.save!.should == true }

        specify { expect { subject.save }.to change { subject.persisted? }.from(false).to(true) }
        specify { expect { subject.save! }.to change { subject.persisted? }.from(false).to(true) }

        specify { expect { subject.save }.to change { Storage.storage.keys }.from([]).to([subject.id]) }
        specify { expect { subject.save! }.to change { Storage.storage.keys }.from([]).to([subject.id]) }

        context 'save failed' do
          before { User.define_save { false } }

          it { should_not be_persisted }

          specify { subject.save.should == false }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }

          specify { expect { subject.save }.not_to change { subject.persisted? } }
          specify { expect { subject.save! rescue nil }.not_to change { subject.persisted? } }
        end
      end

      context 'update' do
        subject! { User.new(name: 'Jonny').tap(&:save).tap { |u| u.name = 'Jimmy' } }

        it { should be_valid }
        it { should be_persisted }

        specify { subject.save.should == true }
        specify { subject.save!.should == true }

        specify { expect { subject.save }.not_to change { subject.persisted? } }
        specify { expect { subject.save! }.not_to change { subject.persisted? } }

        specify { expect { subject.save }.to change { Storage.storage[subject.id] }
          .from(hash_including(name: 'Jonny')).to(hash_including(name: 'Jimmy')) }
        specify { expect { subject.save! }.to change { Storage.storage[subject.id] }
          .from(hash_including(name: 'Jonny')).to(hash_including(name: 'Jimmy')) }

        context 'save failed' do
          before { User.define_save { false } }

          it { should be_persisted }

          specify { subject.save.should == false }
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

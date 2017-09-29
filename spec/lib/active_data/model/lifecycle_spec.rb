require 'spec_helper'

describe ActiveData::Model::Lifecycle do
  context do
    before do
      stub_model(:user) do
        include ActiveData::Model::Lifecycle
      end
    end

    subject { User.new }

    %i[save create update destroy].each do |action|
      specify { expect { subject.public_send "_#{action}_performer=", '' }.to raise_error NoMethodError }
    end

    context 'performer execution' do
      let(:foo) { true }

      specify { expect { subject.save { foo } }.to raise_error NameError }
      specify { expect { subject.save { |_| attributes } }.to raise_error NameError }
      specify { expect(subject.save { attributes }).to eq(true) }
      specify { expect(subject.save { |_| foo }).to eq(true) }
    end

    context 'save' do
      specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
      specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }

      specify { expect(subject.save { true }).to eq(true) }
      specify { expect(subject.save! { true }).to eq(true) }

      context 'instance performer' do
        before { subject.define_save { false } }

        specify { expect(subject.save).to eq(false) }
        specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
      end

      context 'create performer' do
        before { User.define_create { true } }

        specify { expect(subject.save).to eq(true) }
        specify { expect(subject.save!).to eq(true) }

        context do
          subject { User.create }

          specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
          specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }
        end

        context 'instance performer' do
          before { subject.define_create { false } }

          specify { expect(subject.save).to eq(false) }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
        end
      end

      context 'update performer' do
        before { User.define_update { true } }

        specify { expect { subject.save }.to raise_error ActiveData::UnsavableObject }
        specify { expect { subject.save! }.to raise_error ActiveData::UnsavableObject }

        context do
          subject { User.new.tap { |u| u.save { true } } }

          specify { expect(subject.save).to eq(true) }
          specify { expect(subject.save!).to eq(true) }

          context 'instance performer' do
            before { subject.define_update { false } }

            specify { expect(subject.save).to eq(false) }
            specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }
          end
        end
      end

      context 'performers execution' do
        before do
          stub_model(:user) do
            include ActiveData::Model::Lifecycle

            attribute :actions, Array, default: []

            def append(action)
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
          expect(subject.actions).to eq(%i[destroy create update destroy destroy create])
        end
      end
    end

    context 'destroy' do
      specify { expect { subject.destroy }.to raise_error ActiveData::UndestroyableObject }
      specify { expect { subject.destroy! }.to raise_error ActiveData::UndestroyableObject }

      specify { expect(subject.destroy { true }).to be_a User }
      specify { expect(subject.destroy! { true }).to be_a User }

      context 'instance performer' do
        before { subject.define_save { false } }

        specify { expect(subject.save).to eq(false) }
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

        attribute :id, Integer, &:generate_id
        attribute :name, String
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

      it { is_expected.to be_a User }
      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }

      context 'invalid' do
        subject { User.create }

        it { is_expected.to be_a User }
        it { is_expected.to be_invalid }
        it { is_expected.not_to be_persisted }
      end
    end

    describe '.create!' do
      subject { User.create!(name: 'Jonny') }

      it { is_expected.to be_a User }
      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }

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

      specify do
        expect { subject.update(name: 'Jonny') }
          .to change { Storage.storage.keys }.from([]).to([subject.id])
      end
      specify do
        expect { subject.update!(name: 'Jonny') }
          .to change { Storage.storage.keys }.from([]).to([subject.id])
      end
    end

    describe '#update_attributes, #update_attributes!' do
      subject { User.new }

      specify { expect { subject.update_attributes(name: 'Jonny') }.to change { subject.persisted? }.from(false).to(true) }
      specify { expect { subject.update_attributes!(name: 'Jonny') }.to change { subject.persisted? }.from(false).to(true) }

      specify { expect { subject.update_attributes({}) }.not_to change { subject.persisted? } }
      specify { expect { subject.update_attributes!({}) }.to raise_error ActiveData::ValidationError }

      specify do
        expect { subject.update_attributes(name: 'Jonny') }
          .to change { Storage.storage.keys }.from([]).to([subject.id])
      end
      specify do
        expect { subject.update_attributes!(name: 'Jonny') }
          .to change { Storage.storage.keys }.from([]).to([subject.id])
      end
    end

    describe '#save, #save!' do
      context 'invalid' do
        subject { User.new }

        it { is_expected.to be_invalid }
        it { is_expected.not_to be_persisted }

        specify { expect(subject.save).to eq(false) }
        specify { expect { subject.save! }.to raise_error ActiveData::ValidationError }

        specify { expect { subject.save }.not_to change { subject.persisted? } }
        specify do
          expect { muffle(ActiveData::ValidationError) { subject.save! } }
            .not_to change { subject.persisted? }
        end
      end

      context 'create' do
        subject { User.new(name: 'Jonny') }

        it { is_expected.to be_valid }
        it { is_expected.not_to be_persisted }

        specify { expect(subject.save).to eq(true) }
        specify { expect(subject.save!).to eq(true) }

        specify { expect { subject.save }.to change { subject.persisted? }.from(false).to(true) }
        specify { expect { subject.save! }.to change { subject.persisted? }.from(false).to(true) }

        specify { expect { subject.save }.to change { Storage.storage.keys }.from([]).to([subject.id]) }
        specify { expect { subject.save! }.to change { Storage.storage.keys }.from([]).to([subject.id]) }

        context 'save failed' do
          before { User.define_save { false } }

          it { is_expected.not_to be_persisted }

          specify { expect(subject.save).to eq(false) }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }

          specify { expect { subject.save }.not_to change { subject.persisted? } }
          specify do
            expect { muffle(ActiveData::ObjectNotSaved) { subject.save! } }
              .not_to change { subject.persisted? }
          end
        end
      end

      context 'update' do
        subject! { User.new(name: 'Jonny').tap(&:save).tap { |u| u.name = 'Jimmy' } }

        it { is_expected.to be_valid }
        it { is_expected.to be_persisted }

        specify { expect(subject.save).to eq(true) }
        specify { expect(subject.save!).to eq(true) }

        specify { expect { subject.save }.not_to change { subject.persisted? } }
        specify { expect { subject.save! }.not_to change { subject.persisted? } }

        specify do
          expect { subject.save }.to change { Storage.storage[subject.id] }
            .from(hash_including(name: 'Jonny')).to(hash_including(name: 'Jimmy'))
        end
        specify do
          expect { subject.save! }.to change { Storage.storage[subject.id] }
            .from(hash_including(name: 'Jonny')).to(hash_including(name: 'Jimmy'))
        end

        context 'save failed' do
          before { User.define_save { false } }

          it { is_expected.to be_persisted }

          specify { expect(subject.save).to eq(false) }
          specify { expect { subject.save! }.to raise_error ActiveData::ObjectNotSaved }

          specify { expect { subject.save }.not_to change { subject.persisted? } }
          specify do
            expect { muffle(ActiveData::ObjectNotSaved) { subject.save! } }
              .not_to change { subject.persisted? }
          end
        end
      end
    end

    describe '#destroy, #destroy!' do
      subject { User.create(name: 'Jonny') }

      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }
      it { is_expected.not_to be_destroyed }

      specify { expect(subject.destroy).to eq(subject) }
      specify { expect(subject.destroy!).to eq(subject) }

      specify { expect { subject.destroy }.to change { subject.persisted? }.from(true).to(false) }
      specify { expect { subject.destroy! }.to change { subject.persisted? }.from(true).to(false) }

      specify { expect { subject.destroy }.to change { subject.destroyed? }.from(false).to(true) }
      specify { expect { subject.destroy! }.to change { subject.destroyed? }.from(false).to(true) }

      specify { expect { subject.destroy }.to change { Storage.storage.keys }.from([subject.id]).to([]) }
      specify { expect { subject.destroy! }.to change { Storage.storage.keys }.from([subject.id]).to([]) }

      context 'save failed' do
        before { User.define_destroy { false } }

        it { is_expected.to be_persisted }

        specify { expect(subject.destroy).to eq(subject) }
        specify { expect { subject.destroy! }.to raise_error ActiveData::ObjectNotDestroyed }

        specify { expect { subject.destroy }.not_to change { subject.persisted? } }
        specify do
          expect { muffle(ActiveData::ObjectNotDestroyed) { subject.destroy! } }
            .not_to change { subject.persisted? }
        end

        specify { expect { subject.destroy }.not_to change { subject.destroyed? } }
        specify do
          expect { muffle(ActiveData::ObjectNotDestroyed) { subject.destroy! } }
            .not_to change { subject.destroyed? }
        end
      end
    end
  end
end

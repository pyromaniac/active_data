require 'spec_helper'
require 'active_data/base'

describe ActiveData::Model::Associations::Reflections::EmbedsAny do
  describe '#build' do
    subject { described_class.build(User, User, :projects) {}.klass.new }

    before do
      stub_model(:project) do
        include ActiveData::Model::Lifecycle
        attribute :title, String
      end
      stub_model(:user) do
        include ActiveData::Model::Associations

        attribute :name, String
        embeds_many :projects
      end
    end

    it { is_expected.to be_a(ActiveData::Model) }
    it { is_expected.to be_a(ActiveData::Model::Primary) }
    it { is_expected.to be_a(ActiveData::Model::Lifecycle) }
    it { is_expected.to be_a(ActiveData::Model::Associations) }

    context 'when ActiveData.base_concern is defined' do
      before do
        stub_const('MyModule', Module.new)

        allow(ActiveData).to receive(:base_concern).and_return(MyModule)

        stub_model(:user) do
          include ActiveData::Model::Associations

          embeds_many :projects
        end
      end

      it { is_expected.to be_a(MyModule) }
    end
  end
end

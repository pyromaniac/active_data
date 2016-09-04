require 'spec_helper'

describe ActiveData::Model::Associations::Validations do
  before do
    stub_model(:project) do
      include ActiveData::Model::Lifecycle
      include ActiveData::Model::Associations

      attribute :title, String
      validates :title, presence: true

      embeds_one :author do
        attribute :name, String
        validates :name, presence: true
      end
    end

    stub_model(:profile) do
      include ActiveData::Model::Lifecycle

      attribute :first_name, String
      attribute :last_name, String
      validates :first_name, presence: true
    end

    stub_model(:user) do
      include ActiveData::Model::Associations

      attribute :login, String
      validates :login, presence: true

      embeds_one :profile, validate: false
      embeds_many :projects
    end
  end

  describe '#validate' do
    let(:profile) { Profile.new first_name: 'Name' }
    let(:project) { Project.new title: 'Project' }
    let(:projects) { [project] }
    let(:user) { User.new(login: 'Login', profile: profile, projects: projects) }
    let(:author_attributes) { { name: 'Author' } }
    before { project.build_author(author_attributes) }

    specify { expect(user.validate).to eq(true) }
    specify { expect { user.validate }.not_to change { user.errors.messages } }

    context do
      let(:author_attributes) { {} }

      specify { expect(user.validate).to eq(false) }
      specify do
        expect { user.validate }.to change { user.errors.messages }
          .to(:'projects.0.author.name' => ["can't be blank"])
      end
    end

    context do
      let(:profile) { Profile.new }

      specify { expect(user.validate).to eq(true) }
      specify { expect { user.validate }.not_to change { user.errors.messages } }
    end

    context do
      let(:projects) { [project, Project.new] }

      specify { expect(user.validate).to eq(false) }
      specify do
        expect { user.validate }.to change { user.errors.messages }
          .to(:'projects.1.title' => ["can't be blank"])
      end
    end
  end

  describe '#validate_ancestry, #valid_ancestry?, #invalid_ancestry?' do
    let(:profile) { Profile.new first_name: 'Name' }
    let(:project) { Project.new title: 'Project' }
    let(:projects) { [project] }
    let(:user) { User.new(login: 'Login', profile: profile, projects: projects) }
    let(:author_attributes) { { name: 'Author' } }
    before { project.build_author(author_attributes) }

    specify { expect(user.validate_ancestry).to eq(true) }
    specify { expect(user.validate_ancestry!).to eq(true) }
    specify { expect { user.validate_ancestry! }.not_to raise_error }
    specify { expect(user.valid_ancestry?).to eq(true) }
    specify { expect(user.invalid_ancestry?).to eq(false) }
    specify { expect { user.validate_ancestry }.not_to change { user.errors.messages } }

    context do
      let(:author_attributes) { {} }
      specify { expect(user.validate_ancestry).to eq(false) }
      specify { expect { user.validate_ancestry! }.to raise_error ActiveData::ValidationError }
      specify { expect(user.valid_ancestry?).to eq(false) }
      specify { expect(user.invalid_ancestry?).to eq(true) }
      specify do
        expect { user.validate_ancestry }.to change { user.errors.messages }
          .to(:'projects.0.author.name' => ["can't be blank"])
      end
    end

    context do
      let(:profile) { Profile.new }
      specify { expect(user.validate_ancestry).to eq(false) }
      specify { expect { user.validate_ancestry! }.to raise_error ActiveData::ValidationError }
      specify { expect(user.valid_ancestry?).to eq(false) }
      specify { expect(user.invalid_ancestry?).to eq(true) }
      specify do
        expect { user.validate_ancestry }.to change { user.errors.messages }
          .to(:'profile.first_name' => ["can't be blank"])
      end
    end

    context do
      let(:projects) { [project, Project.new] }
      specify { expect(user.validate_ancestry).to eq(false) }
      specify { expect { user.validate_ancestry! }.to raise_error ActiveData::ValidationError }
      specify { expect(user.valid_ancestry?).to eq(false) }
      specify { expect(user.invalid_ancestry?).to eq(true) }
      specify do
        expect { user.validate_ancestry }.to change { user.errors.messages }
          .to(:'projects.1.title' => ["can't be blank"])
      end

      context do
        before { user.update(login: '') }
        specify do
          expect { user.validate_ancestry }.to change { user.errors.messages }
            .to(:'projects.1.title' => ["can't be blank"], login: ["can't be blank"])
        end
      end
    end
  end

  context 'represent attributes' do
    before do
      stub_class(:author, ActiveRecord::Base) do
        validates :name, presence: true

        # Emulate Active Record association auto save error.
        def errors
          super.tap do |errors|
            errors.add(:'user.email', 'is invalid') if errors[:'user.email'].empty?
          end
        end
      end

      stub_model(:post) do
        include ActiveData::Model::Associations

        references_one :author
        represents :name, of: :author
        represents :email, of: :author
      end
    end

    let(:post) { Post.new(author: Author.new) }

    specify do
      expect { post.validate_ancestry }.to change { post.errors.messages }
        .to(hash_including(:'author.user.email' => ['is invalid'], name: ["can't be blank"]))
    end
    specify do
      expect { post.validate }.to change { post.errors.messages }
        .to(hash_including(:'author.user.email' => ['is invalid'], name: ["can't be blank"]))
    end
  end
end

require 'spec_helper'

describe ActiveData::Model::Validations do
  let(:model) do
    stub_model(:model) do
      attribute :name
      validates :name, presence: true
    end
  end

  describe '#errors' do
    specify { expect(model.new.errors).to be_a ActiveModel::Errors }
    specify { expect(model.new.errors).to be_empty }
  end

  describe '#valid?' do
    specify { expect(model.new).not_to be_valid }
    specify { expect(model.new(name: 'Name')).to be_valid }
  end

  describe '#invalid?' do
    specify { expect(model.new).to be_invalid }
    specify { expect(model.new(name: 'Name')).not_to be_invalid }
  end

  describe '#validate!' do
    specify { expect { model.new.validate! }.to raise_error ActiveData::ValidationError }
    specify { expect(model.new(name: 'Name').validate!).to eq(true) }
    specify { expect { model.new(name: 'Name').validate! }.not_to raise_error }
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

    before { post.validate_ancestry }

    specify { expect(post.errors.messages).to eq(email: ['is invalid'], name: ["can't be blank"]) }
  end
end

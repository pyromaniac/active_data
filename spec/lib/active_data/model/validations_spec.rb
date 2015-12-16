require 'spec_helper'

describe ActiveData::Model::Validations do
  let(:model) do
    stub_model(:model) do
      attribute :name, String
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
end

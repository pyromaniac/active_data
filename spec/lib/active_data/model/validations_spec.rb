require 'spec_helper'

describe ActiveData::Model::Validations do
  let(:model) { stub_model }

  specify { expect(model.new.errors).to be_a ActiveModel::Errors }
  specify { expect(model.new.errors).to be_empty }
end

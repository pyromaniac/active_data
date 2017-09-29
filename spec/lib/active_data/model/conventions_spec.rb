require 'spec_helper'

describe ActiveData::Model::Conventions do
  let(:model) { stub_model }

  specify { expect([model].flatten).to eq([model]) }
  specify { expect(model.i18n_scope).to eq(:active_data) }
  specify { expect(model.new).not_to be_persisted }
  specify { expect(model.new).to be_new_record }
  specify { expect(model.new).to be_new_object }
end

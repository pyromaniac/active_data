require 'spec_helper'

describe ActiveData::Model do
  let(:model) { stub_model }
  specify { expect { model.blablabla }.to raise_error NoMethodError }

  context 'Fault tolerance' do
    specify { expect { model.new(foo: 'bar') }.not_to raise_error }
  end
end

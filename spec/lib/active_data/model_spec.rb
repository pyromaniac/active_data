# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model do

  let(:model) do
    Class.new do
      include ActiveData::Model

      attribute :name
      attribute :count, default: 0
    end
  end

  specify{model.i18n_scope.should == :active_data}
  specify{model.new.should_not be_persisted}
  specify{model.instantiate({}).should be_an_instance_of model}
  specify{model.instantiate({}).should be_persisted}

  context 'Fault tolerance' do
    specify{ expect { model.new(:foo => 'bar') }.not_to raise_error }
  end
end
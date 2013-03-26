# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations::EmbedsMany do

  class OneAssoc
    include ActiveData::Model

    attribute :name
  end

  let(:klass) do
    Class.new do
      include ActiveData::Model

      attribute :name
      embeds_one :one_assoc
    end
  end

  let(:instance) { klass.new(:name => 'world') }

  context do
    specify { instance.one_assoc.should be_nil }
  end

  context 'accessor with objects' do
    before { instance.one_assoc = OneAssoc.new(name: 'foo') }
    specify { instance.one_assoc.should be_instance_of OneAssoc }
    specify { instance.one_assoc.name.should == 'foo' }
  end

  context 'accessor with attributes' do
    before { instance.one_assoc = { name: 'foo' } }
    specify { instance.one_assoc.should be_instance_of OneAssoc }
    specify { instance.one_assoc.name.should == 'foo' }
  end
end

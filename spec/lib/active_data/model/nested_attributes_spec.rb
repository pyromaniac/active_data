# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Associations do

  class Assoc
    include ActiveData::Model

    attribute :name
  end

  let(:klass) do
    Class.new do
      include ActiveData::Model

      attribute :name
      embeds_many :assocs

      accepts_nested_attributes_for :assocs
    end
  end

  let(:instance){klass.new(:name => 'world')}

  context do
    before { instance.assocs_attributes = [{:name => 'foo'}, {:name => 'bar'}] }
    specify { instance.assocs.count.should == 2 }
    specify { instance.assocs.first.name.should == 'foo' }
    specify { instance.assocs.last.name.should == 'bar' }
  end

  context do
    before { instance.assocs_attributes = {1 => {:name => 'baz'}, 2 => {:name => 'foo'}} }
    specify { instance.assocs.count.should == 2 }
    specify { instance.assocs.first.name.should == 'baz' }
    specify { instance.assocs.last.name.should == 'foo' }
  end

  context do
    before { instance.assocs_attributes = {1 => {:name => 'baz'}, 2 => {:name => 'foo'}} }
    specify { instance.to_params.should == {
      "name" => "world",
      "assocs_attributes" => {'0' => {"name" => "baz"}, '1' => {"name" => "foo"}}
    } }
  end
end

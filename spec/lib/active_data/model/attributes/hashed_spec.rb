# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Attributes::Hashed do
  def build_field(options = {}, &block)
    described_class.new(:field, options.reverse_merge(mode: :hashed), &block)
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v.delete_if { |k, _| k == 'x' } },
      default: 'world', enum: ['hello', '42']) }

    specify { field.read_value(nil, self).should == {} }
    specify { field.read_value({}, self).should == {} }
    specify { field.read_value({a: 1}, self).should == {'a' => 'world'} }
    specify { field.read_value({a: 42}, self).should == {'a' => '42'} }
    specify { field.read_value({a: 'hello', b: '42'}, self).should == {'a' => 'hello', 'b' => '42'} }
    specify { field.read_value({a: 'hello', b: '1'}, self).should == {'a' => 'hello', 'b' => 'world'} }
    specify { field.read_value({a: 'hello', x: '42'}, self).should == {'a' => 'hello'} }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value_before_type_cast(nil, self).should == {} }
    specify { field.read_value_before_type_cast({}, self).should == {} }
    specify { field.read_value_before_type_cast({a: 1}, self).should == {'a' => 1} }
    specify { field.read_value_before_type_cast({a: 42}, self).should == {'a' => 42} }
    specify { field.read_value_before_type_cast({a: 'hello', b: '42'}, self).should == {'a' => 'hello', 'b' => '42'} }
    specify { field.read_value_before_type_cast({a: 'hello', b: '1'}, self).should == {'a' => 'hello', 'b' => '1'} }
    specify { field.read_value_before_type_cast({a: 'hello', x: '42'}, self).should == {'a' => 'hello', 'x' => '42'} }
  end

  context 'integration' do

  end
end

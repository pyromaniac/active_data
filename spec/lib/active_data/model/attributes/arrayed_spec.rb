# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Attributes::Arrayed do
  def build_field(options = {}, &block)
    described_class.new(:field, options.reverse_merge(mode: :arrayed), &block)
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v.uniq.compact }, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value(nil, self).should == [] }
    specify { field.read_value([nil], self).should == [] }
    specify { field.read_value('hello', self).should == ['hello'] }
    specify { field.read_value([42], self).should == ['42'] }
    specify { field.read_value([43], self).should == ['world'] }
    specify { field.read_value([''], self).should == ['world'] }
    specify { field.read_value(['hello', 42], self).should == ['hello', '42'] }
    specify { field.read_value(['hello', false], self).should == ['hello'] }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value_before_type_cast(nil, self).should == [] }
    specify { field.read_value_before_type_cast([nil], self).should == [nil] }
    specify { field.read_value_before_type_cast('hello', self).should == ['hello'] }
    specify { field.read_value_before_type_cast([42], self).should == [42] }
    specify { field.read_value_before_type_cast([43], self).should == [43] }
    specify { field.read_value_before_type_cast([''], self).should == [''] }
    specify { field.read_value_before_type_cast(['hello', 42], self).should == ['hello', 42] }
    specify { field.read_value_before_type_cast(['hello', false], self).should == ['hello', false] }
  end

  context 'integration' do

  end
end
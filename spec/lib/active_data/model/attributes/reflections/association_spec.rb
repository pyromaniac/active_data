require 'spec_helper'

describe ActiveData::Model::Attributes::Reflections::Association do
  def reflection(options = {})
    described_class.new(:field, options)
  end

  describe '.build' do
    before { stub_class(:target) }
    specify do
      described_class.build(Target, :field)

      expect(Target).not_to be_method_defined(:field)
    end
  end

  describe '#alias_attribute' do
    before { stub_class(:target) }

    specify { expect { described_class.build(Target, :field).alias_attribute(:field_alias, Target) }.to raise_error NotImplementedError }
  end
end

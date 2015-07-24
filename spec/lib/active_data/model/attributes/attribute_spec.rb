require 'spec_helper'

describe ActiveData::Model::Attributes::Attribute do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Attribute.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end
end

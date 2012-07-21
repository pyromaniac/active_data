# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Serializable do

  let(:klass) do
    Class.new do
      include ActiveData::Model::Attributable
      attr_reader :name

      attribute :string, type: String
      attribute :integer, type: Integer
      attribute :boolean, type: Boolean
      attribute :array, type: Array

      def initialize name = nil
        @attributes = self.class.initialize_attributes
        @name = name
      end
    end
  end

  subject{klass.new}

  context 'string' do
    specify{subject.tap{|s| s.string = 'hello'}.string.should == 'hello'}
    specify{subject.tap{|s| s.string = 123}.string.should == '123'}
    specify{subject.tap{|s| s.string = nil}.string.should == nil}
  end

  context 'integer' do
    specify{subject.tap{|s| s.integer = 'hello'}.integer.should == nil}
    specify{subject.tap{|s| s.integer = '123hello'}.integer.should == nil}
    specify{subject.tap{|s| s.integer = '123'}.integer.should == 123}
    specify{subject.tap{|s| s.integer = 123}.integer.should == 123}
    specify{subject.tap{|s| s.integer = nil}.integer.should == nil}
    specify{subject.tap{|s| s.integer = [123]}.integer.should == nil}
  end

  context 'boolean' do
    specify{subject.tap{|s| s.boolean = 'hello'}.boolean.should == nil}
    specify{subject.tap{|s| s.boolean = 'true'}.boolean.should == true}
    specify{subject.tap{|s| s.boolean = 'false'}.boolean.should == false}
    specify{subject.tap{|s| s.boolean = '1'}.boolean.should == true}
    specify{subject.tap{|s| s.boolean = '0'}.boolean.should == false}
    specify{subject.tap{|s| s.boolean = true}.boolean.should == true}
    specify{subject.tap{|s| s.boolean = false}.boolean.should == false}
    specify{subject.tap{|s| s.boolean = 1}.boolean.should == true}
    specify{subject.tap{|s| s.boolean = 0}.boolean.should == false}
    specify{subject.tap{|s| s.boolean = nil}.boolean.should == nil}
    specify{subject.tap{|s| s.boolean = [123]}.boolean.should == nil}
  end

  context 'array' do
    specify{subject.tap{|s| s.array = [1, 2, 3]}.array.should == [1, 2, 3]}
    specify{subject.tap{|s| s.array = 'hello, world'}.array.should == ['hello', 'world']}
    specify{subject.tap{|s| s.array = 10}.array.should == nil}
  end

end
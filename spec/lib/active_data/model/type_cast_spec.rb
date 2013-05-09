# encoding: UTF-8
require 'spec_helper'

describe 'typecasting' do

  let(:klass) do
    Class.new do
      include ActiveData::Model::Attributable
      attr_reader :name

      attribute :string, type: String
      attribute :integer, type: Integer
      attribute :float, type: Float
      attribute :big_decimal, type: BigDecimal
      attribute :boolean, type: Boolean
      attribute :array, type: Array
      attribute :date, type: Date
      attribute :datetime, type: DateTime
      attribute :time, type: Time
      attribute :custom_time, typecast: ->(value){ Time.at(value.to_i).utc }

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
    specify{subject.tap{|s| s.integer = '123.5'}.integer.should == 123}
    specify{subject.tap{|s| s.integer = 123}.integer.should == 123}
    specify{subject.tap{|s| s.integer = 123.5}.integer.should == 123}
    specify{subject.tap{|s| s.integer = nil}.integer.should == nil}
    specify{subject.tap{|s| s.integer = [123]}.integer.should == nil}
  end

  context 'float' do
    specify{subject.tap{|s| s.float = 'hello'}.float.should == nil}
    specify{subject.tap{|s| s.float = '123hello'}.float.should == nil}
    specify{subject.tap{|s| s.float = '123'}.float.should == 123.0}
    specify{subject.tap{|s| s.float = '123.'}.float.should == nil}
    specify{subject.tap{|s| s.float = '123.5'}.float.should == 123.5}
    specify{subject.tap{|s| s.float = 123}.float.should == 123.0}
    specify{subject.tap{|s| s.float = 123.5}.float.should == 123.5}
    specify{subject.tap{|s| s.float = nil}.float.should == nil}
    specify{subject.tap{|s| s.float = [123.5]}.float.should == nil}
  end

  context 'big_decimal' do
    specify{subject.tap{|s| s.big_decimal = 'hello'}.big_decimal.should == nil}
    specify{subject.tap{|s| s.big_decimal = '123hello'}.big_decimal.should == nil}
    specify{subject.tap{|s| s.big_decimal = '123'}.big_decimal.should == BigDecimal.new('123.0')}
    specify{subject.tap{|s| s.big_decimal = '123.'}.big_decimal.should == nil}
    specify{subject.tap{|s| s.big_decimal = '123.5'}.big_decimal.should == BigDecimal.new('123.5')}
    specify{subject.tap{|s| s.big_decimal = 123}.big_decimal.should == BigDecimal.new('123.0')}
    specify{subject.tap{|s| s.big_decimal = 123.5}.big_decimal.should == BigDecimal.new('123.5')}
    specify{subject.tap{|s| s.big_decimal = nil}.big_decimal.should == nil}
    specify{subject.tap{|s| s.big_decimal = [123.5]}.big_decimal.should == nil}
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

  context 'date' do
    let(:date) { Date.new(2013, 6, 13) }
    specify{subject.tap{|s| s.date = nil}.date.should == nil}
    specify{subject.tap{|s| s.date = '2013-06-13'}.date.should == date}
    specify{subject.tap{|s| s.date = '2013-55-55'}.date.should == nil}
    specify{subject.tap{|s| s.date = DateTime.new(2013, 6, 13, 23, 13)}.date.should == date}
    specify{subject.tap{|s| s.date = Time.new(2013, 6, 13, 23, 13)}.date.should == date}
  end

  context 'datetime' do
    let(:datetime) { DateTime.new(2013, 6, 13, 23, 13) }
    specify{subject.tap{|s| s.datetime = nil}.datetime.should == nil}
    specify{subject.tap{|s| s.datetime = '2013-06-13 23:13'}.datetime.should == datetime}
    specify{subject.tap{|s| s.datetime = '2013-55-55 55:55'}.datetime.should == nil}
    specify{subject.tap{|s| s.datetime = Date.new(2013, 6, 13)}.datetime.should == DateTime.new(2013, 6, 13, 0, 0)}
    specify{subject.tap{|s| s.datetime = Time.utc_time(2013, 6, 13, 23, 13).utc}.datetime.should == DateTime.new(2013, 6, 13, 23, 13)}
  end

  context 'time' do
    let(:time) { Time.utc_time(2013, 6, 13, 23, 13) }
    specify{subject.tap{|s| s.time = nil}.time.should == nil}
    specify{subject.tap{|s| s.time = '2013-06-13 23:13'}.time.should == time}
    specify{subject.tap{|s| s.time = '2013-55-55 55:55'}.time.should == nil}
    specify{subject.tap{|s| s.time = Date.new(2013, 6, 13)}.time.should == Time.new(2013, 6, 13, 0, 0)}
    specify{subject.tap{|s| s.time = DateTime.new(2013, 6, 13, 23, 13)}.time.should == time}
  end

  context 'custom_time' do
    let(:time) { Time.utc_time(2013, 6, 13, 23, 13) }
    specify{subject.tap{|s| s.custom_time = '1371165180'}.custom_time.should == time}
    specify{subject.tap{|s| s.custom_time = 1371165180}.custom_time.should == time}
  end
end
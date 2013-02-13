# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributable do

  let(:klass) do
    Class.new do
      include ActiveData::Model::Attributable
      attr_reader :name

      attribute :hello
      attribute :count, type: Integer, default: 10
      attribute(:calc, type: Integer) { 2 + 3 }
      attribute :enum, type: Integer, in: [1, 2, 3]

      def initialize name = nil
        @attributes = self.class.initialize_attributes
        @name = name
      end
    end
  end

  context do
    subject { klass.new('world') }
    specify { klass.enum_values == [1, 2, 3] }
    its(:attributes) { should ==  { "hello"=>nil, "count"=>10, "calc"=>5, "enum" => nil }  }
    its(:present_attributes) { should ==  { "count"=>10, "calc"=>5 }  }
    its(:name) { should == 'world' }
    its(:hello) { should be_nil }
    its(:count) { should == 10 }
    its(:calc) { should == 5 }
    specify { expect { subject.hello = 'worlds' } .to change { subject.hello } .from(nil).to('worlds') }
    specify { expect { subject.count = 20 } .to change { subject.count } .from(10).to(20) }
    specify { expect { subject.calc = 15 } .to change { subject.calc } .from(5).to(15) }
  end

  context 'calculating default values' do
    let(:klass) do
      Class.new do
        include ActiveData::Model::Attributable

        attribute(:rand, type: Integer) { rand 1000000 }

        def initialize
          @attributes = self.class.initialize_attributes
        end
      end
    end

    subject { klass.new }
    specify { subject.rand.should == subject.rand }
  end

end

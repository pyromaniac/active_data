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
    its(:attributes) { should ==  { hello: nil, count: 10, calc: 5, enum: nil }  }
    its(:present_attributes) { should ==  { count: 10, calc: 5 }  }
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

  context 'attribute caching' do
    subject { klass.new('world') }

    context do
      before do
        subject.should_receive(:_read_attribute).with(:hello).once
      end

      specify { subject.hello }
    end

    context do
      before do
        subject.hello
        subject.should_not_receive(:_read_attribute)
      end

      specify { subject.hello }
    end

    context 'attribute cache reset' do
      before do
        subject.hello = 'blabla'
        subject.hello
        subject.hello = 'newnewnew'
      end

      specify { subject.hello.should == 'newnewnew' }
    end
  end

  context 'inheritance' do
    let!(:ancestor) do
      Class.new do
        include ActiveData::Model::Attributable
        attribute :foo
      end
    end

    let!(:descendant1) do
      Class.new ancestor do
        attribute :bar
      end
    end

    let!(:descendant2) do
      Class.new ancestor do
        attribute :baz
        attribute :moo
      end
    end

    specify { ancestor._attributes.keys.should == [:foo] }
    specify { ancestor.instance_methods.should include :foo, :foo= }
    specify { ancestor.instance_methods.should_not include :bar, :bar=, :baz, :baz= }
    specify { descendant1._attributes.keys.should == [:foo, :bar] }
    specify { descendant1.instance_methods.should include :foo, :foo=, :bar, :bar= }
    specify { descendant1.instance_methods.should_not include :baz, :baz= }
    specify { descendant2._attributes.keys.should == [:foo, :baz, :moo] }
    specify { descendant2.instance_methods.should include :foo, :foo=, :baz, :baz=, :moo, :moo= }
    specify { descendant2.instance_methods.should_not include :bar, :bar= }
  end

  context '#write_attributes' do
    subject { klass.new('world') }

    specify { expect { subject.write_attributes(strange: 'value') }.to raise_error NoMethodError }

    context do
      before { subject.write_attributes('hello' => 'blabla', count: 20) }
      specify { subject.attributes.should == { hello: 'blabla', count: 20, calc: 5, enum: nil } }
    end
  end

end

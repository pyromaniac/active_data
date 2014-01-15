# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Attributes::Base do
  def build_field(options = {}, &block)
    described_class.new(:field, options, &block)
  end

  describe '#name' do
    specify { build_field.name.should == 'field' }
  end

  describe '#type' do
    specify { build_field.type.should == Object }
    specify { build_field(type: String).type.should == String }
  end

  describe '#type_cast' do
    specify { build_field.type_cast('hello').should == 'hello' }
    specify { build_field(type: Integer).type_cast(42).should == 42 }
    specify { build_field(type: Integer).type_cast('42').should == 42 }
  end

  describe '#enum' do
    specify { build_field.enum.should == [].to_set }
    specify { build_field(enum: []).enum.should == [].to_set }
    specify { build_field(enum: 'hello').enum.should == ['hello'].to_set }
    specify { build_field(enum: ['hello', 'world']).enum.should == ['hello', 'world'].to_set }
    specify { build_field(enum: [1..5]).enum.should == [1..5].to_set }
    specify { build_field(enum: 1..5).enum.should == (1..5).to_a.to_set }
  end

  describe '#enumerize' do
    specify { build_field.enumerize('hello').should == 'hello' }
    specify { build_field(enum: ['hello', 42]).enumerize('hello').should == 'hello' }
    specify { build_field(enum: ['hello', 42]).enumerize('world').should == nil }
  end

  describe '#default' do
    specify { build_field.default.should be_nil }
    specify { build_field(default: 42).default.should == 42 }
    specify { build_field { }.default.should be_a Proc }
  end

  describe '#default_blank' do
    specify { build_field.default_blank.should be_nil }
    specify { build_field(default_blank: 42).default_blank.should == 42 }
  end

  describe '#default_value' do
    let(:default) { 42 }

    specify { build_field.default_value(self).should == nil }
    specify { build_field(default_blank: 'hello').default_value(self).should == 'hello' }
    specify { build_field(default: 'hello').default_value(self).should == 'hello' }
    specify { build_field(default: 'hello1', default_blank: 'hello2').default_value(self).should == 'hello1' }
    specify { build_field { default }.default_value(self).should == 42 }
    specify { build_field { |context| context.default }.default_value(self).should == 42 }
  end

  describe '#defaultize' do
    context do
      let(:value) { 'value' }
      let(:field) { build_field(default: ->{ value }) }

      specify { field.defaultize(nil, self).should == 'value' }
    end

    context do
      let(:value) { 'value' }
      let(:field) { build_field(default: ->(instance) { instance.value }) }

      specify { field.defaultize(nil, self).should == 'value' }
    end

    context 'default_blank: false' do
      let(:field) { build_field(default: 'world') }

      specify { field.defaultize('hello', self).should == 'hello' }
      specify { field.defaultize('', self).should == '' }
      specify { field.defaultize(nil, self).should == 'world' }

      context do
        let(:field) { build_field(type: Boolean, default: true) }

        specify { field.defaultize(nil, self).should == true }
        specify { field.defaultize(true, self).should == true }
        specify { field.defaultize(false, self).should == false }
      end
    end

    context 'default_blank: value' do
      let(:field) { build_field(default_blank: 'world') }

      specify { field.defaultize('hello', self).should == 'hello' }
      specify { field.defaultize('', self).should == 'world' }
      specify { field.defaultize(nil, self).should == 'world' }

      context do
        let(:field) { build_field(type: Boolean, default_blank: true) }

        specify { field.defaultize(nil, self).should == true }
        specify { field.defaultize(true, self).should == true }
        specify { field.defaultize(false, self).should == false }
      end
    end

    context 'default_blank: true' do
      let(:field) { build_field(default: 'world', default_blank: true) }

      specify { field.defaultize('hello', self).should == 'hello' }
      specify { field.defaultize('', self).should == 'world' }
      specify { field.defaultize(nil, self).should == 'world' }

      context do
        let(:field) { build_field(type: Boolean, default_blank: true, default: true) }

        specify { field.defaultize(nil, self).should == true }
        specify { field.defaultize(true, self).should == true }
        specify { field.defaultize(false, self).should == false }
      end
    end
  end

  describe '#normalizers' do
    specify { build_field.normalizers.should == [] }
    specify { build_field(normalizer: ->{}).normalizers.should be_a Array }
    specify { build_field(normalizer: ->{}).normalizers.first.should be_a Proc }
  end

  describe '#normalize' do
    specify { build_field.normalize(' hello ', self).should == ' hello ' }
    specify { build_field(normalizer: ->(v){ v.strip }).normalize(' hello ', self).should == 'hello' }
    specify { build_field(normalizer: [->(v){ v.strip }, ->(v){ v.first(4) }]).normalize(' hello ', self).should == 'hell' }
    specify { build_field(normalizer: [->(v){ v.first(4) }, ->(v){ v.strip }]).normalize(' hello ', self).should == 'hel' }

    context do
      let(:value) { 'value' }
      specify { build_field(normalizer: ->(v){ value }).normalize(' hello ', self).should == 'value' }
    end

    context 'integration' do
      before do
        ActiveData.stub(config: ActiveData::Config.send(:new))
        ActiveData.normalizer(:strip) do |value|
          value.strip
        end
        ActiveData.normalizer(:trim) do |value, options|
          value.first(length || options[:length] || 2)
        end
      end

      let(:length) { nil }

      specify { build_field(normalizer: :strip).normalize(' hello ', self).should == 'hello' }
      specify { build_field(normalizer: [:strip, :trim]).normalize(' hello ', self).should == 'he' }
      specify { build_field(normalizer: [:trim, :strip]).normalize(' hello ', self).should == 'h' }
      specify { build_field(normalizer: [:strip, { trim: { length: 4 } }]).normalize(' hello ', self).should == 'hell' }
      specify { build_field(normalizer: {strip: { }, trim: { length: 4 } }).normalize(' hello ', self).should == 'hell' }
      specify { build_field(normalizer: [:strip, { trim: { length: 4 } }, ->(v){ v.last(2) }])
        .normalize(' hello ', self).should == 'll' }

      context do
        let(:length) { 3 }

        specify { build_field(normalizer: [:strip, { trim: { length: 4 } }]).normalize(' hello ', self).should == 'hel' }
        specify { build_field(normalizer: {strip: { }, trim: { length: 4 } }).normalize(' hello ', self).should == 'hel' }
        specify { build_field(normalizer: [:strip, { trim: { length: 4 } }, ->(v){ v.last(2) }])
        .normalize(' hello ', self).should == 'el' }
      end
    end
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v ? v.strip : v }, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value(nil, self).should == 'world' }
    specify { field.read_value('hello', self).should == 'hello' }
    specify { field.read_value(' hello ', self).should == 'world' }
    specify { field.read_value(42, self).should == '42' }
    specify { field.read_value(43, self).should == 'world' }
    specify { field.read_value('', self).should == 'world' }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v.strip }, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value_before_type_cast(nil, self).should == nil }
    specify { field.read_value_before_type_cast('hello', self).should == 'hello' }
    specify { field.read_value_before_type_cast(42, self).should == 42 }
    specify { field.read_value_before_type_cast(43, self).should == 43 }
    specify { field.read_value_before_type_cast('', self).should == '' }
  end
end

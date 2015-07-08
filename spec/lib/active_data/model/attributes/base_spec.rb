# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Base do
  def build_field(options = {}, &block)
    described_class.new(:field, options, &block)
  end

  describe '#name' do
    specify { expect(build_field.name).to eq('field') }
  end

  describe '#type' do
    specify { expect(build_field.type).to eq(Object) }
    specify { expect(build_field(type: String).type).to eq(String) }
    specify { expect(build_field(type: :time).type).to eq(Time) }
  end

  describe '#type_cast' do
    specify { expect(build_field.type_cast('hello')).to eq('hello') }
    specify { expect(build_field(type: Integer).type_cast(42)).to eq(42) }
    specify { expect(build_field(type: Integer).type_cast('42')).to eq(42) }
  end

  describe '#enum' do
    specify { expect(build_field.enum(self)).to eq([].to_set) }
    specify { expect(build_field(enum: []).enum(self)).to eq([].to_set) }
    specify { expect(build_field(enum: 'hello').enum(self)).to eq(['hello'].to_set) }
    specify { expect(build_field(enum: ['hello', 'world']).enum(self)).to eq(['hello', 'world'].to_set) }
    specify { expect(build_field(enum: [1..5]).enum(self)).to eq([1..5].to_set) }
    specify { expect(build_field(enum: 1..5).enum(self)).to eq((1..5).to_a.to_set) }
    specify { expect(build_field(enum: -> { 1..5 }).enum(self)).to eq((1..5).to_a.to_set) }
    specify { expect(build_field(enum: -> { 'hello' }).enum(self)).to eq(['hello'].to_set) }
    specify { expect(build_field(enum: -> { ['hello', 42] }).enum(self)).to eq(['hello', 42].to_set) }
  end

  describe '#enumerize' do
    specify { expect(build_field.enumerize('hello', self)).to eq('hello') }
    specify { expect(build_field(enum: ['hello', 42]).enumerize('hello', self)).to eq('hello') }
    specify { expect(build_field(enum: ['hello', 42]).enumerize('world', self)).to eq(nil) }
    specify { expect(build_field(enum: -> { 'hello' }).enumerize('hello', self)).to eq('hello') }
    specify { expect(build_field(enum: -> { 1..5 }).enumerize(2, self)).to eq(2) }
    specify { expect(build_field(enum: -> { 1..5 }).enumerize(42, self)).to eq(nil) }
  end

  describe '#default' do
    specify { expect(build_field.default).to be_nil }
    specify { expect(build_field(default: 42).default).to eq(42) }
    specify { expect(build_field { }.default).to be_a Proc }
  end

  describe '#default_blank' do
    specify { expect(build_field.default_blank).to be_nil }
    specify { expect(build_field(default_blank: 42).default_blank).to eq(42) }
  end

  describe '#default_value' do
    let(:default) { 42 }

    specify { expect(build_field.default_value(self)).to eq(nil) }
    specify { expect(build_field(default_blank: 'hello').default_value(self)).to eq('hello') }
    specify { expect(build_field(default: 'hello').default_value(self)).to eq('hello') }
    specify { expect(build_field(default: 'hello1', default_blank: 'hello2').default_value(self)).to eq('hello1') }
    specify { expect(build_field { default }.default_value(self)).to eq(42) }
    specify { expect(build_field { |context| context.default }.default_value(self)).to eq(42) }
  end

  describe '#defaultize' do
    context do
      let(:value) { 'value' }
      let(:field) { build_field(default: ->{ value }) }

      specify { expect(field.defaultize(nil, self)).to eq('value') }
    end

    context do
      let(:value) { 'value' }
      let(:field) { build_field(default: ->(instance) { instance.value }) }

      specify { expect(field.defaultize(nil, self)).to eq('value') }
    end

    context 'default_blank: false' do
      let(:field) { build_field(default: 'world') }

      specify { expect(field.defaultize('hello', self)).to eq('hello') }
      specify { expect(field.defaultize('', self)).to eq('') }
      specify { expect(field.defaultize(nil, self)).to eq('world') }

      context do
        let(:field) { build_field(type: Boolean, default: true) }

        specify { expect(field.defaultize(nil, self)).to eq(true) }
        specify { expect(field.defaultize(true, self)).to eq(true) }
        specify { expect(field.defaultize(false, self)).to eq(false) }
      end
    end

    context 'default_blank: value' do
      let(:field) { build_field(default_blank: 'world') }

      specify { expect(field.defaultize('hello', self)).to eq('hello') }
      specify { expect(field.defaultize('', self)).to eq('world') }
      specify { expect(field.defaultize(nil, self)).to eq('world') }

      context do
        let(:field) { build_field(type: Boolean, default_blank: true) }

        specify { expect(field.defaultize(nil, self)).to eq(true) }
        specify { expect(field.defaultize(true, self)).to eq(true) }
        specify { expect(field.defaultize(false, self)).to eq(false) }
      end
    end

    context 'default_blank: true' do
      let(:field) { build_field(default: 'world', default_blank: true) }

      specify { expect(field.defaultize('hello', self)).to eq('hello') }
      specify { expect(field.defaultize('', self)).to eq('world') }
      specify { expect(field.defaultize(nil, self)).to eq('world') }

      context do
        let(:field) { build_field(type: Boolean, default_blank: true, default: true) }

        specify { expect(field.defaultize(nil, self)).to eq(true) }
        specify { expect(field.defaultize(true, self)).to eq(true) }
        specify { expect(field.defaultize(false, self)).to eq(false) }
      end
    end
  end

  describe '#normalizers' do
    specify { expect(build_field.normalizers).to eq([]) }
    specify { expect(build_field(normalizer: ->{}).normalizers).to be_a Array }
    specify { expect(build_field(normalizer: ->{}).normalizers.first).to be_a Proc }
  end

  describe '#normalize' do
    specify { expect(build_field.normalize(' hello ', self)).to eq(' hello ') }
    specify { expect(build_field(normalizer: ->(v){ v.strip }).normalize(' hello ', self)).to eq('hello') }
    specify { expect(build_field(normalizer: [->(v){ v.strip }, ->(v){ v.first(4) }]).normalize(' hello ', self)).to eq('hell') }
    specify { expect(build_field(normalizer: [->(v){ v.first(4) }, ->(v){ v.strip }]).normalize(' hello ', self)).to eq('hel') }

    context do
      let(:value) { 'value' }
      specify { expect(build_field(normalizer: ->(v){ value }).normalize(' hello ', self)).to eq('value') }
    end

    context 'integration' do
      before do
        allow(ActiveData).to receive_messages(config: ActiveData::Config.send(:new))
        ActiveData.normalizer(:strip) do |value|
          value.strip
        end
        ActiveData.normalizer(:trim) do |value, options|
          value.first(length || options[:length] || 2)
        end
      end

      let(:length) { nil }

      specify { expect(build_field(normalizer: :strip).normalize(' hello ', self)).to eq('hello') }
      specify { expect(build_field(normalizer: [:strip, :trim]).normalize(' hello ', self)).to eq('he') }
      specify { expect(build_field(normalizer: [:trim, :strip]).normalize(' hello ', self)).to eq('h') }
      specify { expect(build_field(normalizer: [:strip, { trim: { length: 4 } }]).normalize(' hello ', self)).to eq('hell') }
      specify { expect(build_field(normalizer: {strip: { }, trim: { length: 4 } }).normalize(' hello ', self)).to eq('hell') }
      specify { expect(build_field(normalizer: [:strip, { trim: { length: 4 } }, ->(v){ v.last(2) }])
        .normalize(' hello ', self)).to eq('ll') }

      context do
        let(:length) { 3 }

        specify { expect(build_field(normalizer: [:strip, { trim: { length: 4 } }]).normalize(' hello ', self)).to eq('hel') }
        specify { expect(build_field(normalizer: {strip: { }, trim: { length: 4 } }).normalize(' hello ', self)).to eq('hel') }
        specify { expect(build_field(normalizer: [:strip, { trim: { length: 4 } }, ->(v){ v.last(2) }])
          .normalize(' hello ', self)).to eq('el') }
      end
    end
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v ? v.strip : v }, default: 'world', enum: ['hello', '42']) }

    specify { expect(field.read_value(nil, self)).to eq('world') }
    specify { expect(field.read_value('hello', self)).to eq('hello') }
    specify { expect(field.read_value(' hello ', self)).to eq('world') }
    specify { expect(field.read_value(42, self)).to eq('42') }
    specify { expect(field.read_value(43, self)).to eq('world') }
    specify { expect(field.read_value('', self)).to eq('world') }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, normalizer: ->(v){ v.strip }, default: 'world', enum: ['hello', '42']) }

    specify { expect(field.read_value_before_type_cast(nil, self)).to eq('world') }
    specify { expect(field.read_value_before_type_cast('hello', self)).to eq('hello') }
    specify { expect(field.read_value_before_type_cast(42, self)).to eq(42) }
    specify { expect(field.read_value_before_type_cast(43, self)).to eq(43) }
    specify { expect(field.read_value_before_type_cast('', self)).to eq('') }
  end
end

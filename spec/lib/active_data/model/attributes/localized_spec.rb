# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Attributes::Localized do
  def build_field(options = {}, &block)
    described_class.new(:field, options.reverse_merge(mode: :localized), &block)
  end

  describe '#read_value' do
    let(:field) { build_field(type: String, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value(nil, self).should == {} }
    specify { field.read_value({ en: 'hello' }, self).should == { 'en' => 'hello' } }
    specify { field.read_value({ en: 42 }, self).should == { 'en' => '42' } }
    specify { field.read_value({ en: 43 }, self).should == { 'en' => 'world' } }
    specify { field.read_value({ en: '' }, self).should == { 'en' => 'world' } }
    specify { field.read_value({ en: 'hello', ru: 42 }, self).should == { 'en' => 'hello', 'ru' => '42' } }
  end

  describe '#read_value_before_type_cast' do
    let(:field) { build_field(type: String, default: 'world', enum: ['hello', '42']) }

    specify { field.read_value_before_type_cast(nil, self).should == {} }
    specify { field.read_value_before_type_cast({ en: 'hello' }, self).should == { 'en' => 'hello' } }
    specify { field.read_value_before_type_cast({ en: 42 }, self).should == { 'en' => 42 } }
    specify { field.read_value_before_type_cast({ en: 43 }, self).should == { 'en' => 43 } }
    specify { field.read_value_before_type_cast({ en: '' }, self).should == { 'en' => '' } }
    specify { field.read_value_before_type_cast({ en: 'hello', ru: 42 }, self).should == { 'en' => 'hello', 'ru' => 42 } }
  end

  context 'integration' do
    let(:klass) do
      Class.new do
        include ActiveData::Model

        attribute :name, type: String, mode: :localized
      end
    end
    let(:translations) { { en: 'Hello', ru: 'Привет' } }
    before { I18n.locale = :en }

    describe '#name_translations' do
      subject { klass.new name_translations: translations }
      its(:name_translations) { should == translations.stringify_keys }
      its(:name) { should == translations[:en] }
    end

    describe '#name' do
      subject { klass.new name: 'Hello' }
      its(:name_translations) { should == { 'en' => 'Hello' } }
      its(:name) { should == 'Hello' }
    end

    describe '#name_before_type_cast' do
      let(:object) { Object.new }
      subject { klass.new name: object }
      its(:name_before_type_cast) { should == object }
    end

    context 'fallbacks' do
      subject { klass.new name_translations: { ru: 'Привет' } }
      context do
        its(:name) { should be_nil }
      end

      context do
        before do
          require "i18n/backend/fallbacks"
          I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
          I18n.fallbacks.map(en: :ru)
        end
        after { I18n.fallbacks = false }
        its(:name) { should == 'Привет' }
      end
    end
  end
end
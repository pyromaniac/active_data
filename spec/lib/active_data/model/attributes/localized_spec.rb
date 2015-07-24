# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Model::Attributes::Localized do
  def attribute(*args)
    options = args.extract_options!
    reflection = ActiveData::Model::Attributes::Reflections::Localized.new(:field, options)
    described_class.new(args.first || Object.new, reflection)
  end

  describe '#read_value' do
    let(:field) { attribute(type: String, default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value(nil)).to eq({}) }
    specify { expect(field.read_value({ en: 'hello' })).to eq({ 'en' => 'hello' }) }
    specify { expect(field.read_value({ en: 42 })).to eq({ 'en' => '42' }) }
    specify { expect(field.read_value({ en: 43 })).to eq({ 'en' => nil }) }
    specify { expect(field.read_value({ en: '' })).to eq({ 'en' => nil }) }
    specify { expect(field.read_value({ en: nil })).to eq({ 'en' => nil }) }
    specify { expect(field.read_value({ en: 'hello', ru: 42 })).to eq({ 'en' => 'hello', 'ru' => '42' }) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.read_value(nil)).to eq({}) }
      specify { expect(field.read_value({ en: 'hello' })).to eq({ 'en' => 'hello' }) }
      specify { expect(field.read_value({ en: 42 })).to eq({ 'en' => '42' }) }
      specify { expect(field.read_value({ en: '' })).to eq({ 'en' => '' }) }
      specify { expect(field.read_value({ en: nil })).to eq({ 'en' => 'world' }) }
    end
  end

  describe '#read_value_before_type_cast' do
    let(:field) { attribute(type: String, default: :world, enum: ['hello', '42']) }

    specify { expect(field.read_value_before_type_cast(nil)).to eq({}) }
    specify { expect(field.read_value_before_type_cast({ en: 'hello' })).to eq({ 'en' => 'hello' }) }
    specify { expect(field.read_value_before_type_cast({ en: 42 })).to eq({ 'en' => 42 }) }
    specify { expect(field.read_value_before_type_cast({ en: 43 })).to eq({ 'en' => 43 }) }
    specify { expect(field.read_value_before_type_cast({ en: '' })).to eq({ 'en' => '' }) }
    specify { expect(field.read_value_before_type_cast({ en: nil })).to eq({ 'en' => :world }) }
    specify { expect(field.read_value_before_type_cast({ en: 'hello', ru: 42 })).to eq({ 'en' => 'hello', 'ru' => 42 }) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.read_value_before_type_cast(nil)).to eq({}) }
      specify { expect(field.read_value_before_type_cast({ en: 'hello' })).to eq({ 'en' => 'hello' }) }
      specify { expect(field.read_value_before_type_cast({ en: 42 })).to eq({ 'en' => 42 }) }
      specify { expect(field.read_value_before_type_cast({ en: '' })).to eq({ 'en' => '' }) }
      specify { expect(field.read_value_before_type_cast({ en: nil })).to eq({ 'en' => :world }) }
    end
  end

  context 'integration' do
    let(:klass) do
      Class.new do
        include ActiveData::Model
        include ActiveData::Model::Localization

        localized :name, type: String
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

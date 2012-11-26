# encoding: UTF-8
require 'spec_helper'

describe Localized do
  let(:klass) do
    Class.new do
      include ActiveData::Model

      attribute :name, type: Localized
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
      its(:name) { should == 'Привет' }
    end
  end
end
require 'spec_helper'

describe ActiveData::Model::Attributes::Localized do
  before { stub_model(:dummy) }

  def attribute(*args)
    options = args.extract_options!
    Dummy.add_attribute(ActiveData::Model::Attributes::Reflections::Localized, :field, options)
    described_class.new('field', Dummy.new)
  end

  describe '#read' do
    let(:field) { attribute(type: String, default: :world, enum: %w[hello 42]) }

    specify { expect(field.tap { |r| r.write(nil) }.read).to eq({}) }
    specify { expect(field.tap { |r| r.write(en: 'hello') }.read).to eq('en' => 'hello') }
    specify { expect(field.tap { |r| r.write(en: 42) }.read).to eq('en' => '42') }
    specify { expect(field.tap { |r| r.write(en: 43) }.read).to eq('en' => nil) }
    specify { expect(field.tap { |r| r.write(en: '') }.read).to eq('en' => nil) }
    specify { expect(field.tap { |r| r.write(en: nil) }.read).to eq('en' => nil) }
    specify { expect(field.tap { |r| r.write(en: 'hello', ru: 42) }.read).to eq('en' => 'hello', 'ru' => '42') }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.tap { |r| r.write(nil) }.read).to eq({}) }
      specify { expect(field.tap { |r| r.write(en: 'hello') }.read).to eq('en' => 'hello') }
      specify { expect(field.tap { |r| r.write(en: 42) }.read).to eq('en' => '42') }
      specify { expect(field.tap { |r| r.write(en: '') }.read).to eq('en' => '') }
      specify { expect(field.tap { |r| r.write(en: nil) }.read).to eq('en' => 'world') }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, default: :world, enum: %w[hello 42]) }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq({}) }
    specify { expect(field.tap { |r| r.write(en: 'hello') }.read_before_type_cast).to eq('en' => 'hello') }
    specify { expect(field.tap { |r| r.write(en: 42) }.read_before_type_cast).to eq('en' => 42) }
    specify { expect(field.tap { |r| r.write(en: 43) }.read_before_type_cast).to eq('en' => 43) }
    specify { expect(field.tap { |r| r.write(en: '') }.read_before_type_cast).to eq('en' => '') }
    specify { expect(field.tap { |r| r.write(en: nil) }.read_before_type_cast).to eq('en' => :world) }
    specify { expect(field.tap { |r| r.write(en: 'hello', ru: 42) }.read_before_type_cast).to eq('en' => 'hello', 'ru' => 42) }

    context do
      let(:field) { attribute(type: String, default: :world) }

      specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq({}) }
      specify { expect(field.tap { |r| r.write(en: 'hello') }.read_before_type_cast).to eq('en' => 'hello') }
      specify { expect(field.tap { |r| r.write(en: 42) }.read_before_type_cast).to eq('en' => 42) }
      specify { expect(field.tap { |r| r.write(en: '') }.read_before_type_cast).to eq('en' => '') }
      specify { expect(field.tap { |r| r.write(en: nil) }.read_before_type_cast).to eq('en' => :world) }
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
    let(:translations) { {en: 'Hello', ru: 'Привет'} }
    before { I18n.locale = :en }

    describe '#name_translations' do
      subject { klass.new name_translations: translations }
      its(:name_translations) { should == translations.stringify_keys }
      its(:name) { should == translations[:en] }
    end

    describe '#name' do
      subject { klass.new name: 'Hello' }
      its(:name_translations) { should == {'en' => 'Hello'} }
      its(:name) { should == 'Hello' }
    end

    describe '#name_before_type_cast' do
      let(:object) { Object.new }
      subject { klass.new name: object }
      its(:name_before_type_cast) { should == object }
    end

    context 'fallbacks' do
      subject { klass.new name_translations: {ru: 'Привет'} }
      context do
        its(:name) { should be_nil }
      end

      context do
        before do
          require 'i18n/backend/fallbacks'
          I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
          I18n.fallbacks.map(en: :ru)
        end
        after { I18n.fallbacks = false }
        its(:name) { should == 'Привет' }
      end
    end
  end
end

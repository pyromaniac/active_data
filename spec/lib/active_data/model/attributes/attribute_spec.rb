require 'spec_helper'

describe ActiveData::Model::Attributes::Attribute do
  before { stub_model(:dummy) }

  def attribute(*args)
    options = args.extract_options!
    Dummy.add_attribute(ActiveData::Model::Attributes::Reflections::Attribute, :field, {type: Object}.merge(options))
    Dummy.new.attribute(:field)
  end

  describe '#read' do
    let(:field) { attribute(type: String, normalizer: ->(v) { v ? v.strip : v }, default: :world, enum: %w[hello 42 world]) }

    specify { expect(field.tap { |r| r.write(nil) }.read).to eq('world') }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq('world') }
    specify { expect(field.tap { |r| r.write('hello') }.read).to eq('hello') }
    specify { expect(field.tap { |r| r.write(' hello ') }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write(42) }.read).to eq('42') }
    specify { expect(field.tap { |r| r.write(43) }.read).to eq(nil) }
    specify { expect(field.tap { |r| r.write('') }.read).to eq(nil) }

    context ':readonly' do
      specify { expect(attribute(readonly: true, default: :world).tap { |r| r.write('string') }.read).to eq(:world) }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, normalizer: ->(v) { v.strip }, default: :world, enum: %w[hello 42 world]) }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write('hello') }.read_before_type_cast).to eq('hello') }
    specify { expect(field.tap { |r| r.write(42) }.read_before_type_cast).to eq(42) }
    specify { expect(field.tap { |r| r.write(43) }.read_before_type_cast).to eq(43) }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }

    context ':readonly' do
      specify { expect(attribute(readonly: true, default: :world).tap { |r| r.write('string') }.read_before_type_cast).to eq(:world) }
    end
  end

  describe '#default' do
    before { allow_any_instance_of(Dummy).to receive_messages(value: 42) }

    specify { expect(attribute.default).to eq(nil) }
    specify { expect(attribute(default: 'hello').default).to eq('hello') }
    specify { expect(attribute(default: -> { value }).default).to eq(42) }
    specify { expect(attribute(default: ->(object) { object.value }).default).to eq(42) }
    specify { expect(attribute(default: ->(*args) { args.first.value }).default).to eq(42) }
  end

  describe '#defaultize' do
    specify { expect(attribute.defaultize(nil)).to be_nil }
    specify { expect(attribute(default: 'hello').defaultize(nil)).to eq('hello') }
    specify { expect(attribute(default: 'hello').defaultize('world')).to eq('world') }
    specify { expect(attribute(default: false, type: Boolean).defaultize(nil)).to eq(false) }
  end

  describe '#typecast' do
    context 'when Object' do
      specify { expect(attribute.typecast(:hello)).to eq(:hello) }
    end

    context 'when Integer' do
      specify { expect(attribute(type: Integer).typecast(42)).to eq(42) }
      specify { expect(attribute(type: Integer).typecast('42')).to eq(42) }
    end

    context 'when Hash' do
      let(:to_h) { {'x' => {'foo' => 'bar'}, 'y' => 2} }
      let(:parameters) { ActionController::Parameters.new(to_h) }

      before(:all) do
        @default_hash_typecaster = ActiveData.typecaster('Hash')
        require 'action_controller'
        Class.new(ActionController::Base)
        @action_controller_hash_typecaster = ActiveData.typecaster('Hash')
      end

      context 'when ActionController is loaded' do
        before { ActiveData.typecaster('Hash', &@action_controller_hash_typecaster) }
        after { ActiveData.typecaster('Hash', &@default_hash_typecaster) }

        specify { expect(attribute(type: Hash).typecast(nil)).to be_nil }
        specify { expect(attribute(type: Hash).typecast(to_h)).to eq(to_h) }
        specify { expect(attribute(type: Hash).typecast(parameters)).to be_nil }
        specify { expect(attribute(type: Hash).typecast(parameters.permit(:y, x: [:foo]))).to eq(to_h) }
      end

      context 'when ActionController is not loaded' do
        before { ActiveData.typecaster('Hash', &@default_hash_typecaster) }

        specify { expect(attribute(type: Hash).typecast(nil)).to be_nil }
        specify { expect(attribute(type: Hash).typecast(to_h)).to eq(to_h) }
        if ActiveSupport.version > Gem::Version.new('4.3')
          specify { expect(attribute(type: Hash).typecast(parameters.permit(:y, x: [:foo]))).to be_nil }
        else
          specify { expect(attribute(type: Hash).typecast(parameters.permit(:y, x: [:foo]))).to eq(to_h) }
        end
      end
    end
  end

  describe '#enum' do
    before { allow_any_instance_of(Dummy).to receive_messages(value: 1..5) }

    specify { expect(attribute.enum).to eq([].to_set) }
    specify { expect(attribute(enum: []).enum).to eq([].to_set) }
    specify { expect(attribute(enum: 'hello').enum).to eq(['hello'].to_set) }
    specify { expect(attribute(enum: %w[hello world]).enum).to eq(%w[hello world].to_set) }
    specify { expect(attribute(enum: [1..5]).enum).to eq([1..5].to_set) }
    specify { expect(attribute(enum: 1..5).enum).to eq((1..5).to_a.to_set) }
    specify { expect(attribute(enum: -> { 1..5 }).enum).to eq((1..5).to_a.to_set) }
    specify { expect(attribute(enum: -> { 'hello' }).enum).to eq(['hello'].to_set) }
    specify { expect(attribute(enum: -> { ['hello', 42] }).enum).to eq(['hello', 42].to_set) }
    specify { expect(attribute(enum: -> { value }).enum).to eq((1..5).to_a.to_set) }
    specify { expect(attribute(enum: ->(object) { object.value }).enum).to eq((1..5).to_a.to_set) }
  end

  describe '#enumerize' do
    specify { expect(attribute.enumerize('anything')).to eq('anything') }
    specify { expect(attribute(enum: ['hello', 42]).enumerize('hello')).to eq('hello') }
    specify { expect(attribute(enum: ['hello', 42]).enumerize('world')).to eq(nil) }
    specify { expect(attribute(enum: -> { 'hello' }).enumerize('hello')).to eq('hello') }
    specify { expect(attribute(enum: -> { 1..5 }).enumerize(2)).to eq(2) }
    specify { expect(attribute(enum: -> { 1..5 }).enumerize(42)).to eq(nil) }
  end

  describe '#normalize' do
    specify { expect(attribute.normalize(' hello ')).to eq(' hello ') }
    specify { expect(attribute(normalizer: ->(v) { v.strip }).normalize(' hello ')).to eq('hello') }
    specify { expect(attribute(normalizer: [->(v) { v.strip }, ->(v) { v.first(4) }]).normalize(' hello ')).to eq('hell') }
    specify { expect(attribute(normalizer: [->(v) { v.first(4) }, ->(v) { v.strip }]).normalize(' hello ')).to eq('hel') }

    context do
      before { allow_any_instance_of(Dummy).to receive_messages(value: 'value') }
      let(:other) { 'other' }

      specify { expect(attribute(normalizer: ->(_v) { value }).normalize(' hello ')).to eq('value') }
      specify { expect(attribute(normalizer: ->(_v, object) { object.value }).normalize(' hello ')).to eq('value') }
      specify { expect(attribute(normalizer: ->(_v, _object) { other }).normalize(' hello ')).to eq('other') }
    end

    context 'integration' do
      before do
        allow(ActiveData).to receive_messages(config: ActiveData::Config.send(:new))
        ActiveData.normalizer(:strip) { |value, _, _| value.strip }
        ActiveData.normalizer(:trim) do |value, options, _attribute|
          value.first(length || options[:length] || 2)
        end
        ActiveData.normalizer(:reset) do |value, _options, attribute|
          empty = value.respond_to?(:empty?) ? value.empty? : value.nil?
          empty ? attribute.default : value
        end
      end

      let(:length) { nil }

      specify { expect(attribute(normalizer: :strip).normalize(' hello ')).to eq('hello') }
      specify { expect(attribute(normalizer: %i[strip trim]).normalize(' hello ')).to eq('he') }
      specify { expect(attribute(normalizer: %i[trim strip]).normalize(' hello ')).to eq('h') }
      specify { expect(attribute(normalizer: [:strip, {trim: {length: 4}}]).normalize(' hello ')).to eq('hell') }
      specify { expect(attribute(normalizer: {strip: {}, trim: {length: 4}}).normalize(' hello ')).to eq('hell') }
      specify do
        expect(attribute(normalizer: [:strip, {trim: {length: 4}}, ->(v) { v.last(2) }])
        .normalize(' hello ')).to eq('ll')
      end
      specify { expect(attribute(normalizer: :reset).normalize('')).to eq(nil) }
      specify { expect(attribute(normalizer: %i[strip reset]).normalize('   ')).to eq(nil) }
      specify { expect(attribute(normalizer: :reset, default: '!!!').normalize(nil)).to eq('!!!') }
      specify { expect(attribute(normalizer: :reset, default: '!!!').normalize('')).to eq('!!!') }

      context do
        let(:length) { 3 }

        specify { expect(attribute(normalizer: [:strip, {trim: {length: 4}}]).normalize(' hello ')).to eq('hel') }
        specify { expect(attribute(normalizer: {strip: {}, trim: {length: 4}}).normalize(' hello ')).to eq('hel') }
        specify do
          expect(attribute(normalizer: [:strip, {trim: {length: 4}}, ->(v) { v.last(2) }])
          .normalize(' hello ')).to eq('el')
        end
      end
    end
  end
end

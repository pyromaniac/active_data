# encoding: UTF-8
require 'spec_helper'

describe 'typecasting' do
  let(:klass) do
    stub_class do
      include ActiveData::Model::Attributes
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
      attribute :time_zone, type: ActiveSupport::TimeZone
      attribute :uuid, type: ActiveData::UUID

      def initialize name = nil
        @attributes = self.class.initialize_attributes
        @name = name
      end
    end
  end

  subject{klass.new}

  context 'string' do
    specify { expect(subject.tap { |s| s.string = 'hello' }.string).to eq('hello') }
    specify { expect(subject.tap { |s| s.string = 123 }.string).to eq('123') }
    specify { expect(subject.tap { |s| s.string = nil }.string).to eq(nil) }
  end

  context 'integer' do
    specify { expect(subject.tap { |s| s.integer = 'hello' }.integer).to eq(nil) }
    specify { expect(subject.tap { |s| s.integer = '123hello' }.integer).to eq(nil) }
    specify { expect(subject.tap { |s| s.integer = '123' }.integer).to eq(123) }
    specify { expect(subject.tap { |s| s.integer = '123.5' }.integer).to eq(123) }
    specify { expect(subject.tap { |s| s.integer = 123 }.integer).to eq(123) }
    specify { expect(subject.tap { |s| s.integer = 123.5 }.integer).to eq(123) }
    specify { expect(subject.tap { |s| s.integer = nil }.integer).to eq(nil) }
    specify { expect(subject.tap { |s| s.integer = [123] }.integer).to eq(nil) }
  end

  context 'float' do
    specify { expect(subject.tap { |s| s.float = 'hello' }.float).to eq(nil) }
    specify { expect(subject.tap { |s| s.float = '123hello' }.float).to eq(nil) }
    specify { expect(subject.tap { |s| s.float = '123' }.float).to eq(123.0) }
    specify { expect(subject.tap { |s| s.float = '123.' }.float).to eq(nil) }
    specify { expect(subject.tap { |s| s.float = '123.5' }.float).to eq(123.5) }
    specify { expect(subject.tap { |s| s.float = 123 }.float).to eq(123.0) }
    specify { expect(subject.tap { |s| s.float = 123.5 }.float).to eq(123.5) }
    specify { expect(subject.tap { |s| s.float = nil }.float).to eq(nil) }
    specify { expect(subject.tap { |s| s.float = [123.5] }.float).to eq(nil) }
  end

  context 'big_decimal' do
    specify { expect(subject.tap { |s| s.big_decimal = 'hello' }.big_decimal).to eq(nil) }
    specify { expect(subject.tap { |s| s.big_decimal = '123hello' }.big_decimal).to eq(nil) }
    specify { expect(subject.tap { |s| s.big_decimal = '123' }.big_decimal).to eq(BigDecimal.new('123.0')) }
    specify { expect(subject.tap { |s| s.big_decimal = '123.' }.big_decimal).to eq(nil) }
    specify { expect(subject.tap { |s| s.big_decimal = '123.5' }.big_decimal).to eq(BigDecimal.new('123.5')) }
    specify { expect(subject.tap { |s| s.big_decimal = 123 }.big_decimal).to eq(BigDecimal.new('123.0')) }
    specify { expect(subject.tap { |s| s.big_decimal = 123.5 }.big_decimal).to eq(BigDecimal.new('123.5')) }
    specify { expect(subject.tap { |s| s.big_decimal = nil }.big_decimal).to eq(nil) }
    specify { expect(subject.tap { |s| s.big_decimal = [123.5] }.big_decimal).to eq(nil) }
  end

  context 'boolean' do
    specify { expect(subject.tap { |s| s.boolean = 'hello' }.boolean).to eq(nil) }
    specify { expect(subject.tap { |s| s.boolean = 'true' }.boolean).to eq(true) }
    specify { expect(subject.tap { |s| s.boolean = 'false' }.boolean).to eq(false) }
    specify { expect(subject.tap { |s| s.boolean = '1' }.boolean).to eq(true) }
    specify { expect(subject.tap { |s| s.boolean = '0' }.boolean).to eq(false) }
    specify { expect(subject.tap { |s| s.boolean = true }.boolean).to eq(true) }
    specify { expect(subject.tap { |s| s.boolean = false }.boolean).to eq(false) }
    specify { expect(subject.tap { |s| s.boolean = 1 }.boolean).to eq(true) }
    specify { expect(subject.tap { |s| s.boolean = 0 }.boolean).to eq(false) }
    specify { expect(subject.tap { |s| s.boolean = nil }.boolean).to eq(nil) }
    specify { expect(subject.tap { |s| s.boolean = [123] }.boolean).to eq(nil) }
  end

  context 'array' do
    specify { expect(subject.tap { |s| s.array = [1, 2, 3] }.array).to eq([1, 2, 3]) }
    specify { expect(subject.tap { |s| s.array = 'hello, world' }.array).to eq(['hello', 'world']) }
    specify { expect(subject.tap { |s| s.array = 10 }.array).to eq(nil) }
  end

  context 'date' do
    let(:date) { Date.new(2013, 6, 13) }

    specify { expect(subject.tap { |s| s.date = nil }.date).to eq(nil) }
    specify { expect(subject.tap { |s| s.date = '2013-06-13' }.date).to eq(date) }
    specify { expect(subject.tap { |s| s.date = '2013-55-55' }.date).to eq(nil) }
    specify { expect(subject.tap { |s| s.date = 'blablabla' }.date).to eq(nil) }
    specify { expect(subject.tap { |s| s.date = DateTime.new(2013, 6, 13, 23, 13) }.date).to eq(date) }
    specify { expect(subject.tap { |s| s.date = Time.new(2013, 6, 13, 23, 13) }.date).to eq(date) }
    specify { expect(subject.tap { |s| s.date = Date.new(2013, 6, 13) }.date).to eq(date) }
  end

  context 'datetime' do
    let(:datetime) { DateTime.new(2013, 6, 13, 23, 13) }

    specify { expect(subject.tap { |s| s.datetime = nil }.datetime).to eq(nil) }
    specify { expect(subject.tap { |s| s.datetime = '2013-06-13 23:13' }.datetime).to eq(datetime) }
    specify { expect(subject.tap { |s| s.datetime = '2013-55-55 55:55' }.datetime).to eq(nil) }
    specify { expect(subject.tap { |s| s.datetime = 'blablabla' }.datetime).to eq(nil) }
    specify { expect(subject.tap { |s| s.datetime = Date.new(2013, 6, 13) }.datetime).to eq(DateTime.new(2013, 6, 13, 0, 0)) }
    specify { expect(subject.tap { |s| s.datetime = Time.utc(2013, 6, 13, 23, 13).utc }.datetime).to eq(DateTime.new(2013, 6, 13, 23, 13)) }
    specify { expect(subject.tap { |s| s.datetime = DateTime.new(2013, 6, 13, 23, 13) }.datetime).to eq(DateTime.new(2013, 6, 13, 23, 13)) }
  end

  context 'time' do
    specify { expect(subject.tap { |s| s.time = nil }.time).to eq(nil) }
    specify { expect(subject.tap { |s| s.time = '2013-06-13 23:13' }.time).to eq('2013-06-13 23:13'.to_time) }
    specify { expect(subject.tap { |s| s.time = '2013-55-55 55:55' }.time).to eq(nil) }
    specify { expect(subject.tap { |s| s.time = 'blablabla' }.time).to eq(nil) }
    specify { expect(subject.tap { |s| s.time = Date.new(2013, 6, 13) }.time).to eq(Time.new(2013, 6, 13, 0, 0)) }
    specify { expect(subject.tap { |s| s.time = DateTime.new(2013, 6, 13, 19, 13) }.time).to eq(DateTime.new(2013, 6, 13, 19, 13).to_time) }
    specify { expect(subject.tap { |s| s.time = Time.new(2013, 6, 13, 23, 13) }.time).to eq(Time.new(2013, 6, 13, 23, 13)) }

    context 'Time.zone set' do
      around { |example| Time.use_zone('Bangkok', &example) }

      specify { expect(subject.tap { |s| s.time = nil }.time).to eq(nil) }
      specify { expect(subject.tap { |s| s.time = '2013-06-13 23:13' }.time).to eq(Time.zone.parse('2013-06-13 23:13')) }
      specify { expect(subject.tap { |s| s.time = '2013-55-55 55:55' }.time).to eq(nil) }
      specify { expect(subject.tap { |s| s.time = 'blablabla' }.time).to eq(nil) }
      specify { expect(subject.tap { |s| s.time = Date.new(2013, 6, 13) }.time).to eq(Time.new(2013, 6, 13, 0, 0)) }
      specify { expect(subject.tap { |s| s.time = DateTime.new(2013, 6, 13, 19, 13) }.time).to eq(DateTime.new(2013, 6, 13, 19, 13).to_time) }
      specify { expect(subject.tap { |s| s.time = Time.new(2013, 6, 13, 23, 13) }.time).to eq(Time.new(2013, 6, 13, 23, 13)) }
    end
  end

  context 'time_zone' do
    specify { expect(subject.tap { |s| s.time_zone = nil }.time_zone).to be_nil }
    specify { expect(subject.tap { |s| s.time_zone = Object.new }.time_zone).to be_nil }
    specify { expect(subject.tap { |s| s.time_zone = Time.now }.time_zone).to be_nil }
    specify { expect(subject.tap { |s| s.time_zone = 'blablabla' }.time_zone).to be_nil }
    specify { expect(subject.tap { |s| s.time_zone = TZInfo::Timezone.all.first }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = 'Moscow' }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = '+4' }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = '-3' }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = '3600' }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = '-7200' }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = 4 }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = -3 }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = 3600 }.time_zone).to be_a ActiveSupport::TimeZone }
    specify { expect(subject.tap { |s| s.time_zone = -7200 }.time_zone).to be_a ActiveSupport::TimeZone }
  end

  context 'uuid' do
    let(:uuid) { ActiveData::UUID.random_create }
    let(:uuid_tools) { UUIDTools::UUID.random_create }

    specify { expect(uuid.as_json).to eq(uuid.to_s) }
    specify { expect(uuid.to_json).to eq("\"#{uuid.to_s}\"") }
    specify { expect(uuid.to_param).to eq(uuid.to_s) }
    specify { expect(uuid.to_query(:key)).to eq("key=#{uuid.to_s}") }

    specify { expect(subject.tap { |s| s.uuid = nil }.uuid).to be_nil }
    specify { expect(subject.tap { |s| s.uuid = Object.new }.uuid).to be_nil }
    specify { expect(subject.tap { |s| s.uuid = uuid_tools }.uuid).to be_a ActiveData::UUID  }
    specify { expect(subject.tap { |s| s.uuid = uuid_tools }.uuid).to eq(uuid_tools) }
    specify { expect(subject.tap { |s| s.uuid = uuid }.uuid).to eq(uuid) }
    specify { expect(subject.tap { |s| s.uuid = uuid.to_s }.uuid).to eq(uuid) }
    specify { expect(subject.tap { |s| s.uuid = uuid.to_i }.uuid).to eq(uuid) }
    specify { expect(subject.tap { |s| s.uuid = uuid.hexdigest }.uuid).to eq(uuid) }
    specify { expect(subject.tap { |s| s.uuid = uuid.raw }.uuid).to eq(uuid) }
  end
end

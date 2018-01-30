require 'spec_helper'

describe ActiveData::Model::Attributes do
  subject { model.new }

  context 'object' do
    before { stub_class(:descendant) }
    let(:model) { stub_model { attribute :column, Object } }

    specify { expect(model.new(column: 'hello').column).to eq('hello') }
    specify { expect(model.new(column: []).column).to eq([]) }
    specify { expect(model.new(column: Descendant.new).column).to be_a(Descendant) }
    specify { expect(model.new(column: Object.new).column).to be_a(Object) }
    specify { expect(model.new(column: nil).column).to be_nil }

    context do
      before { stub_class(:descendant2, Descendant) }
      let(:model) { stub_model { attribute :column, Descendant } }

      specify { expect(model.new(column: 'hello').column).to be_nil }
      specify { expect(model.new(column: []).column).to be_nil }
      specify { expect(model.new(column: Descendant.new).column).to be_a(Descendant) }
      specify { expect(model.new(column: Descendant2.new).column).to be_a(Descendant2) }
      specify { expect(model.new(column: Object.new).column).to be_nil }
      specify { expect(model.new(column: nil).column).to be_nil }
    end
  end

  context 'string' do
    let(:model) { stub_model { attribute :column, String } }

    specify { expect(model.new(column: 'hello').column).to eq('hello') }
    specify { expect(model.new(column: 123).column).to eq('123') }
    specify { expect(model.new(column: nil).column).to be_nil }
  end

  context 'integer' do
    let(:model) { stub_model { attribute :column, Integer } }

    specify { expect(model.new(column: 'hello').column).to be_nil }
    specify { expect(model.new(column: '123hello').column).to be_nil }
    specify { expect(model.new(column: '123').column).to eq(123) }
    specify { expect(model.new(column: '123.5').column).to eq(123) }
    specify { expect(model.new(column: 123).column).to eq(123) }
    specify { expect(model.new(column: 123.5).column).to eq(123) }
    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: [123]).column).to be_nil }
  end

  context 'float' do
    let(:model) { stub_model { attribute :column, Float } }

    specify { expect(model.new(column: 'hello').column).to be_nil }
    specify { expect(model.new(column: '123hello').column).to be_nil }
    specify { expect(model.new(column: '123').column).to eq(123.0) }
    specify { expect(model.new(column: '123.').column).to be_nil }
    specify { expect(model.new(column: '123.5').column).to eq(123.5) }
    specify { expect(model.new(column: 123).column).to eq(123.0) }
    specify { expect(model.new(column: 123.5).column).to eq(123.5) }
    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: [123.5]).column).to be_nil }
  end

  context 'big_decimal' do
    let(:model) { stub_model { attribute :column, BigDecimal } }

    specify { expect(model.new(column: 'hello').column).to be_nil }
    specify { expect(model.new(column: '123hello').column).to be_nil }
    specify { expect(model.new(column: '123').column).to eq(BigDecimal.new('123.0')) }
    specify { expect(model.new(column: '123.').column).to be_nil }
    specify { expect(model.new(column: '123.5').column).to eq(BigDecimal.new('123.5')) }
    specify { expect(model.new(column: 123).column).to eq(BigDecimal.new('123.0')) }
    specify { expect(model.new(column: 123.5).column).to eq(BigDecimal.new('123.5')) }
    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: [123.5]).column).to be_nil }
  end

  context 'boolean' do
    let(:model) { stub_model { attribute :column, Boolean } }

    specify { expect(model.new(column: 'hello').column).to be_nil }
    specify { expect(model.new(column: 'true').column).to eq(true) }
    specify { expect(model.new(column: 'false').column).to eq(false) }
    specify { expect(model.new(column: '1').column).to eq(true) }
    specify { expect(model.new(column: '0').column).to eq(false) }
    specify { expect(model.new(column: true).column).to eq(true) }
    specify { expect(model.new(column: false).column).to eq(false) }
    specify { expect(model.new(column: 1).column).to eq(true) }
    specify { expect(model.new(column: 0).column).to eq(false) }
    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: [123]).column).to be_nil }
  end

  context 'array' do
    let(:model) { stub_model { attribute :column, Array } }

    specify { expect(model.new(column: [1, 2, 3]).column).to eq([1, 2, 3]) }
    specify { expect(model.new(column: 'hello, world').column).to eq(%w[hello world]) }
    specify { expect(model.new(column: 10).column).to be_nil }
  end

  # rubocop:disable Style/DateTime
  context 'date' do
    let(:model) { stub_model { attribute :column, Date } }
    let(:date) { Date.new(2013, 6, 13) }

    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: '2013-06-13').column).to eq(date) }
    specify { expect(model.new(column: '2013-55-55').column).to be_nil }
    specify { expect(model.new(column: 'blablabla').column).to be_nil }
    specify { expect(model.new(column: DateTime.new(2013, 6, 13, 23, 13)).column).to eq(date) }
    specify { expect(model.new(column: Time.new(2013, 6, 13, 23, 13)).column).to eq(date) }
    specify { expect(model.new(column: Date.new(2013, 6, 13)).column).to eq(date) }
  end

  context 'datetime' do
    let(:model) { stub_model { attribute :column, DateTime } }
    let(:datetime) { DateTime.new(2013, 6, 13, 23, 13) }

    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: '2013-06-13 23:13').column).to eq(datetime) }
    specify { expect(model.new(column: '2013-55-55 55:55').column).to be_nil }
    specify { expect(model.new(column: 'blablabla').column).to be_nil }
    specify { expect(model.new(column: Date.new(2013, 6, 13)).column).to eq(DateTime.new(2013, 6, 13, 0, 0)) }
    specify { expect(model.new(column: Time.utc(2013, 6, 13, 23, 13).utc).column).to eq(DateTime.new(2013, 6, 13, 23, 13)) }
    specify { expect(model.new(column: DateTime.new(2013, 6, 13, 23, 13)).column).to eq(DateTime.new(2013, 6, 13, 23, 13)) }
  end

  context 'time' do
    let(:model) { stub_model { attribute :column, Time } }

    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: '2013-06-13 23:13').column).to eq('2013-06-13 23:13'.to_time) }
    specify { expect(model.new(column: '2013-55-55 55:55').column).to be_nil }
    specify { expect(model.new(column: 'blablabla').column).to be_nil }
    specify { expect(model.new(column: Date.new(2013, 6, 13)).column).to eq(Time.new(2013, 6, 13, 0, 0)) }
    specify { expect(model.new(column: DateTime.new(2013, 6, 13, 19, 13)).column).to eq(DateTime.new(2013, 6, 13, 19, 13).to_time) }
    specify { expect(model.new(column: Time.new(2013, 6, 13, 23, 13)).column).to eq(Time.new(2013, 6, 13, 23, 13)) }

    context 'Time.zone set' do
      around { |example| Time.use_zone('Bangkok', &example) }

      specify { expect(model.new(column: nil).column).to be_nil }
      specify { expect(model.new(column: '2013-06-13 23:13').column).to eq(Time.zone.parse('2013-06-13 23:13')) }
      specify { expect(model.new(column: '2013-55-55 55:55').column).to be_nil }
      specify { expect(model.new(column: 'blablabla').column).to be_nil }
      specify { expect(model.new(column: Date.new(2013, 6, 13)).column).to eq(Time.new(2013, 6, 13, 0, 0)) }
      specify { expect(model.new(column: DateTime.new(2013, 6, 13, 19, 13)).column).to eq(DateTime.new(2013, 6, 13, 19, 13).to_time) }
      specify { expect(model.new(column: Time.new(2013, 6, 13, 23, 13)).column).to eq(Time.new(2013, 6, 13, 23, 13)) }
    end
  end
  # rubocop:enable Style/DateTime

  context 'time_zone' do
    let(:model) { stub_model { attribute :column, ActiveSupport::TimeZone } }

    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: Object.new).column).to be_nil }
    specify { expect(model.new(column: Time.now).column).to be_nil }
    specify { expect(model.new(column: 'blablabla').column).to be_nil }
    specify { expect(model.new(column: TZInfo::Timezone.all.first).column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: 'Moscow').column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: '+4').column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: '-3').column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: '3600').column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: '-7200').column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: 4).column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: -3).column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: 3600).column).to be_a ActiveSupport::TimeZone }
    specify { expect(model.new(column: -7200).column).to be_a ActiveSupport::TimeZone }
  end

  context 'uuid' do
    let(:model) { stub_model { attribute :column, ActiveData::UUID } }
    let(:uuid) { ActiveData::UUID.random_create }
    let(:uuid_tools) { UUIDTools::UUID.random_create }

    specify { expect(uuid.as_json).to eq(uuid.to_s) }
    specify { expect(uuid.to_json).to eq("\"#{uuid}\"") }
    specify { expect(uuid.to_param).to eq(uuid.to_s) }
    specify { expect(uuid.to_query(:key)).to eq("key=#{uuid}") }

    specify { expect(model.new(column: nil).column).to be_nil }
    specify { expect(model.new(column: Object.new).column).to be_nil }
    specify { expect(model.new(column: uuid_tools).column).to be_a ActiveData::UUID }
    specify { expect(model.new(column: uuid_tools).column).to eq(uuid_tools) }
    specify { expect(model.new(column: uuid).column).to eq(uuid) }
    specify { expect(model.new(column: uuid.to_s).column).to eq(uuid) }
    specify { expect(model.new(column: uuid.to_i).column).to eq(uuid) }
    specify { expect(model.new(column: uuid.hexdigest).column).to eq(uuid) }
    specify { expect(model.new(column: uuid.raw).column).to eq(uuid) }
  end
end

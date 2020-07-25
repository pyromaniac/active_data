require 'tzinfo'
require 'active_support'
require 'active_support/deprecation'
require 'active_support/core_ext'
require 'active_support/concern'
require 'singleton'

require 'active_model'

require 'active_data/version'
require 'active_data/errors'
require 'active_data/extensions'
require 'active_data/undefined_class'
require 'active_data/config'
require 'active_data/railtie' if defined? Rails
require 'active_data/model'
require 'active_data/model/associations/persistence_adapters/base'
require 'active_data/model/associations/persistence_adapters/active_record'

module ActiveData
  BOOLEAN_MAPPING = {
    1 => true,
    0 => false,
    '1' => true,
    '0' => false,
    't' => true,
    'f' => false,
    'T' => true,
    'F' => false,
    true => true,
    false => false,
    'true' => true,
    'false' => false,
    'TRUE' => true,
    'FALSE' => false,
    'y' => true,
    'n' => false,
    'yes' => true,
    'no' => false
  }.freeze

  def self.config
    ActiveData::Config.instance
  end

  singleton_class.delegate(*ActiveData::Config.delegated, to: :config)

  typecaster('Object') { |value, attribute| value if value.class < attribute.type }
  typecaster('String') { |value, _| value.to_s }
  typecaster('Array') do |value|
    case value
    when ::Array then
      value
    when ::String then
      value.split(',').map(&:strip)
    end
  end
  typecaster('Hash') do |value|
    case value
    when ::Hash then
      value
    end
  end
  ActiveSupport.on_load :action_controller do
    ActiveData.typecaster('Hash') do |value|
      case value
      when ActionController::Parameters
        value.to_h if value.permitted?
      when ::Hash then
        value
      end
    end
  end
  typecaster('Date') do |value|
    begin
      value.to_date
    rescue ArgumentError, NoMethodError
      nil
    end
  end
  typecaster('DateTime') do |value|
    begin
      value.to_datetime
    rescue ArgumentError
      nil
    end
  end
  typecaster('Time') do |value|
    begin
      value.is_a?(String) && ::Time.zone ? ::Time.zone.parse(value) : value.to_time
    rescue ArgumentError
      nil
    end
  end
  typecaster('ActiveSupport::TimeZone') do |value|
    case value
    when ActiveSupport::TimeZone
      value
    when ::TZInfo::Timezone
      ActiveSupport::TimeZone[value.name]
    when String, Numeric, ActiveSupport::Duration
      value = begin
        Float(value)
      rescue ArgumentError, TypeError
        value
      end
      ActiveSupport::TimeZone[value]
    end
  end
  typecaster('BigDecimal') do |value|
    next unless value
    begin
      BigDecimal(Float(value).to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
  typecaster('Float') do |value|
    begin
      Float(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
  typecaster('Integer') do |value|
    begin
      Float(value).to_i
    rescue ArgumentError, TypeError
      nil
    end
  end
  typecaster('Boolean') { |value| BOOLEAN_MAPPING[value] }
  typecaster('ActiveData::UUID') do |value|
    case value
    when UUIDTools::UUID
      ActiveData::UUID.parse_raw value.raw
    when ActiveData::UUID
      value
    when String
      ActiveData::UUID.parse_string value
    when Integer
      ActiveData::UUID.parse_int value
    end
  end
end

require 'active_data/base'

ActiveData.base_class = ActiveData::Base

ActiveSupport.on_load :active_record do
  require 'active_data/active_record/associations'
  require 'active_data/active_record/nested_attributes'

  include ActiveData::ActiveRecord::Associations
  singleton_class.prepend ActiveData::ActiveRecord::NestedAttributes

  def self.active_data_persistence_adapter
    ActiveData::Model::Associations::PersistenceAdapters::ActiveRecord
  end
end

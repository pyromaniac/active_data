require 'active_data/model/extensions'
require 'active_data/model/collectionizable'
require 'active_data/model/attributable'
require 'active_data/model/localizable'
require 'active_data/model/associations'
require 'active_data/model/nested_attributes'
require 'active_data/model/parameterizable'

require 'active_data/attributes/base'
require 'active_data/attributes/localized'

module ActiveData
  module Model
    class NotFound < ::StandardError
    end

    extend ActiveSupport::Concern

    included do
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include ActiveModel::MassAssignmentSecurity
      include ActiveModel::Serialization
      include ActiveModel::Serializers::JSON
      include ActiveModel::Serializers::Xml

      include Attributable
      include Localizable
      include Collectionizable
      include Associations
      include NestedAttributes
      include Parameterizable
      extend ActiveModel::Naming
      extend ActiveModel::Translation

      self.include_root_in_json = false

      def initialize attributes = {}
        @attributes = self.class.initialize_attributes
        @new_record = true
        assign_attributes attributes
      end

      def self.i18n_scope
        :active_data
      end
    end

    module ClassMethods
      def instantiate data
        return data if data.instance_of? self

        data = data.stringify_keys
        instance = allocate

        attributes = initialize_attributes
        attributes.merge!(data.slice(*attributes.keys))

        data.slice(*association_names).each do |association, data|
          instance.send(:"#{association}=", data)
        end

        instance.instance_variable_set(:@attributes, attributes)
        instance.instance_variable_set(:@new_record, false)

        instance
      end
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def persisted?
      !@new_record
    end

    def inspect
      "#<#{self.class} #{attributes.map { |name, value| "#{name}: #{value.inspect}" }.join(' ')}>"
    end

    def == other
      other.instance_of?(self.class) && other.attributes == attributes
    end

    def assign_attributes(attributes, options = {})
      super(sanitize_for_mass_assignment((attributes.presence || {}), options[:as]))
    end

  end
end

module ActiveData
  module Model
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Naming
      extend ActiveModel::Translation

      include ActiveModel::Conversion
      include ActiveModel::Validations
      include ActiveModel::Serialization
      include ActiveModel::Serializers::JSON

      include Conventions
      include Attributes
      include Primary
      include Collection
      include Lifecycle
      include Callbacks
      include Associations

      self.include_root_in_json = ActiveData.include_root_in_json

      def self.i18n_scope
        ActiveData.i18n_scope
      end
    end

    module ClassMethods
      def instantiate data
        data = data.stringify_keys
        instance = allocate

        attributes = initialize_attributes
        attributes.merge!(data.slice(*attributes.keys))

        instance.instance_variable_set(:@attributes, attributes)
        instance.instance_variable_set(:@persisted, true)
        instance.instance_variable_set(:@destroyed, false)

        instance
      end

      def instantiate_collection data
        collection(Array.wrap(data).map { |attrs| instantiate attrs }, true)
      end

      def to_ary
        nil
      end
    end

    def initialize attributes = {}
      @attributes = self.class.initialize_attributes
      @persisted = false
      @destroyed = false
      assign_attributes attributes
    end

    def == other
      other.instance_of?(self.class) && other.attributes == attributes
    end
  end
end

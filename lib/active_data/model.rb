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

      include Attributable
      include Collectionizable
      include ActiveData::Associations

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

        data.slice(*reflections.keys.map(&:to_s)).each do |name, data|
          reflection = reflect_on_association(name)
          data = if reflection.collection?
            reflection.klass.instantiate_collection data
          else
            reflection.klass.instantiate data
          end
          instance.send(:"#{name}=", data)
        end

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

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def persisted?
      @persisted
    end

    def destroyed?
      @destroyed
    end

    def == other
      other.instance_of?(self.class) && other.attributes == attributes
    end

    def inspect
      "#<#{self.class} #{attributes.map { |name, value| "#{name}: #{value.inspect}" }.join(' ')}>"
    end
  end
end

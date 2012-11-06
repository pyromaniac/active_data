require 'active_data/model/associations/many'

module ActiveData
  module Model
    module Associations
      extend ActiveSupport::Concern

      included do
        class_attribute :_associations, :instance_reader => false, :instance_writer => false
        self._associations = ActiveSupport::HashWithIndifferentAccess.new
      end

      module ClassMethods

        def reflect_on_association name
          _associations[name]
        end

        def associations
          _associations
        end

        def association_names
          _associations.keys
        end

        def embeds_many name, options = {}
          association = Many.new name, options
          define_collection_reader association
          define_collection_writer association
          self._associations = _associations.merge!(association.name => association)
        end

        def define_collection_reader association
          define_method association.name do
            instance_variable_get("@#{association.name}") || association.klass.collection([])
          end
        end

        def define_collection_writer association
          define_method "#{association.name}=" do |value|
            instance_variable_set "@#{association.name}", association.klass.collection(value)
          end
        end

      end
    end
  end
end
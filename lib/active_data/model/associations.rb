require 'active_data/model/associations/reflections/base'
require 'active_data/model/associations/reflections/embeds_one'
require 'active_data/model/associations/reflections/embeds_many'
require 'active_data/model/associations/reflections/reference_reflection'
require 'active_data/model/associations/reflections/references_one'
require 'active_data/model/associations/reflections/references_many'

require 'active_data/model/associations/base'
require 'active_data/model/associations/embeds_one'
require 'active_data/model/associations/embeds_many'
require 'active_data/model/associations/references_one'
require 'active_data/model/associations/references_many'
require 'active_data/model/associations/nested_attributes'

require 'active_data/model/associations/collection_proxy'
require 'active_data/model/associations/embedded_collection_proxy'
require 'active_data/model/associations/referenced_collection_proxy'

module ActiveData
  module Model
    module Associations
      extend ActiveSupport::Concern

      included do
        include NestedAttributes

        class_attribute :reflections, instance_reader: false, instance_writer: false
        self.reflections = {}

        {
          embeds_many: Reflections::EmbedsMany,
          embeds_one: Reflections::EmbedsOne,
          references_one: Reflections::ReferencesOne,
          references_many: Reflections::ReferencesMany
        }.each do |(name, reflection_class)|
          define_singleton_method name do |*args, &block|
            reflection = reflection_class.build self, generated_associations_methods, *args, &block
            self.reflections = reflections.merge(reflection.name => reflection)
            reflection
          end
        end
      end

      module ClassMethods
        def reflect_on_association name
          reflections[name.to_sym]
        end

      private

        def attributes_for_inspect
          (reflections.map do |_, reflection|
            "#{reflection.name}: #{reflection.inspect}"
          end + [super]).join(', ')
        end

        def generated_associations_methods
          @generated_associations_methods ||= const_set(:GeneratedAssociationsMethods, Module.new)
            .tap { |proxy| include proxy }
        end
      end

      def == other
        super && association_names.all? do |association|
          public_send(association) == other.public_send(association)
        end
      end
      alias_method :eql?, :==

      def association name
        @_associations ||= {}
        @_associations[name.to_sym] ||= self.class.reflect_on_association(name).build_association(self)
      end

      def association_names
        self.class.reflections.keys
      end

      def save_associations!
        association_names.all? do |name|
          association = association(name)
          result = association.save!
          association.reload
          result
        end
      end

      def valid_ancestry?
        errors.clear
        association_names.each do |name|
          association = association(name)
          if association.collection?
            association.target.each.with_index do |object, i|
              object.respond_to?(:valid_ancestry?) ?
                object.valid_ancestry? :
                object.valid?

              if object.errors.present?
                (errors.messages[name] ||= [])[i] = object.errors.messages
              end
            end
          else
            if association.target
              association.target.respond_to?(:valid_ancestry?) ?
                association.target.valid_ancestry? :
                association.target.valid?

              if association.target.errors.present?
                errors.messages[name] = association.target.errors.messages
              end
            end
          end
        end
        run_validations!
      end
      alias_method :validate_ancestry, :valid_ancestry?

      def invalid_ancestry?
        !valid_ancestry?
      end

      def validate_ancestry!
        valid_ancestry? || raise_validation_error
      end

    private

      def attributes_for_inspect
        (association_names.map do |name|
          association = association(name)
          "#{name}: #{association.inspect}"
        end + [super]).join(', ')
      end
    end
  end
end

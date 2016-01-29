module ActiveData
  module Model
    module Associations
      module NestedAttributes
        extend ActiveSupport::Concern

        DESTROY_ATTRIBUTE = '_destroy'

        included do
          class_attribute :nested_attributes_options, instance_writer: false
          self.nested_attributes_options = {}
        end

        class NestedAttributesMethods
          REJECT_ALL_BLANK_PROC = proc { |attributes| attributes.all? { |key, value| key == DESTROY_ATTRIBUTE || value.blank? } }

          def self.accepts_nested_attributes_for(klass, *attr_names)
            options = { allow_destroy: false, update_only: false }
            options.update(attr_names.extract_options!)
            options.assert_valid_keys(:allow_destroy, :reject_if, :limit, :update_only)
            options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

            attr_names.each do |association_name|
              if reflection = klass.reflect_on_association(association_name)
                klass.nested_attributes_options = klass.nested_attributes_options.merge(association_name.to_sym => options)

                reflection.options[:validate] = true
                type = (reflection.collection? ? :collection : :one_to_one)
                klass.class_eval <<-METHOD, __FILE__, __LINE__ + 1
                  def #{association_name}_attributes=(attributes)
                    ActiveData::Model::Associations::NestedAttributes::NestedAttributesMethods
                      .assign_nested_attributes_for_#{type}_association(self, :#{association_name}, attributes)
                  end
                METHOD
              else
                raise ArgumentError, "No association found for name `#{association_name}'. Has it been defined yet?"
              end
            end
          end

          def self.assign_nested_attributes_for_one_to_one_association(object, association_name, attributes)
            options = object.nested_attributes_options[association_name]
            attributes = attributes.with_indifferent_access

            association = object.association(association_name)
            existing_record = association.target
            primary_attribute_name = primary_name_for(association.reflection.klass)
            if existing_record
              primary_attribute = existing_record.attribute(primary_attribute_name)
              primary_attribute_value = primary_attribute.typecast(attributes[primary_attribute_name]) if primary_attribute
            end

            if existing_record && (!primary_attribute || options[:update_only] || existing_record.primary_attribute == primary_attribute_value)
              assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy]) unless call_reject_if(object, association_name, attributes)
            elsif attributes[primary_attribute_name].present?
              raise ActiveData::ObjectNotFound.new(object, association_name, attributes[primary_attribute_name])
            elsif !reject_new_object?(object, association_name, attributes)
              assignable_attributes = attributes.except(*unassignable_keys(object))

              if existing_record && !existing_record.persisted?
                existing_record.assign_attributes(assignable_attributes)
              else
                association.build(assignable_attributes)
              end
            end
          end

          def self.assign_nested_attributes_for_collection_association(object, association_name, attributes_collection)
            options = object.nested_attributes_options[association_name]

            unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
              raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
            end

            check_record_limit!(options[:limit], attributes_collection)

            association = object.association(association_name)
            primary_attribute_name = primary_name_for(association.reflection.klass)

            if attributes_collection.is_a? Hash
              keys = attributes_collection.keys
              attributes_collection = if keys.include?(primary_attribute_name) || keys.include?(primary_attribute_name.to_sym)
                [attributes_collection]
              else
                attributes_collection.values
              end
            end

            attributes_collection.each do |attributes|
              attributes = attributes.with_indifferent_access

              if attributes[primary_attribute_name].blank?
                unless reject_new_object?(object, association_name, attributes)
                  association.build(attributes.except(*unassignable_keys(object)))
                end
              else
                existing_record = association.target.detect do |record|
                  primary_attribute_value = record.attribute(primary_attribute_name)
                    .typecast(attributes[primary_attribute_name])
                  record.primary_attribute == primary_attribute_value
                end
                if existing_record
                  if !call_reject_if(object, association_name, attributes)
                    assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])
                  end
                else
                  if association.reflection.embedded?
                    unless reject_new_object?(object, association_name, attributes)
                      association.reflection.klass.with_sanitize(false) do
                        association.build(attributes.except(DESTROY_ATTRIBUTE))
                      end
                    end
                  else
                    raise ActiveData::ObjectNotFound.new(object, association_name, attributes[primary_attribute_name])
                  end
                end
              end
            end
          end

          def self.check_record_limit!(limit, attributes_collection)
            if limit
              limit = case limit
              when Symbol
                send(limit)
              when Proc
                limit.call
              else
                limit
              end

              if limit && attributes_collection.size > limit
                raise ActiveData::TooManyObjects.new(limit, attributes_collection.size)
              end
            end
          end

          def self.assign_to_or_mark_for_destruction(object, attributes, allow_destroy)
            object.assign_attributes(attributes.except(*unassignable_keys(object)))
            object.mark_for_destruction if has_destroy_flag?(attributes) && allow_destroy
          end

          def self.has_destroy_flag?(hash)
            ActiveData.typecaster(Boolean).call(hash[DESTROY_ATTRIBUTE])
          end

          def self.reject_new_object?(object, association_name, attributes)
            has_destroy_flag?(attributes) || call_reject_if(object, association_name, attributes)
          end

          def self.call_reject_if(object, association_name, attributes)
            return false if has_destroy_flag?(attributes)
            case callback = object.nested_attributes_options[association_name][:reject_if]
            when Symbol
              method(callback).arity == 0 ? send(callback) : send(callback, attributes)
            when Proc
              callback.call(attributes)
            end
          end

          def self.unassignable_keys(object)
            [primary_name_for(object.class), DESTROY_ATTRIBUTE].compact
          end

          def self.primary_name_for(klass)
            klass < ActiveData::Model ? klass.primary_name : 'id'
          end
        end

        module ClassMethods
          def accepts_nested_attributes_for(*attr_names)
            NestedAttributesMethods.accepts_nested_attributes_for self, *attr_names
          end
        end
      end
    end
  end
end

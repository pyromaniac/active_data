require 'active_data/model/associations/base'

module ActiveData
  module Model
    module Associations
      class ReferencesOne < Base
        delegate :association_primary_key, to: :reflection

        def save
          @previous_identifier = read_source
          target ? (target.marked_for_destruction? ? write_source(nil) : write_source(identifier)) : write_source(nil)
          true
        end
        alias_method :save!, :save

        def target= object
          loaded!
          @target = object
        end

        def target
          return @target if loaded?
          identifier = read_source
          self.target = identifier && reflection.klass.find(identifier)
        end

        def identifier
          target.try(association_primary_key)
        end

        def reload
          write_source(@previous_identifier) if defined?(@previous_identifier) && owner.new_record?
          super
        end

        def reader force_reload = false
          reset if force_reload || source_changed?
          target
        end

        def writer object
          replace object
        end

        def replace object
          unless object.nil?
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
            raise AssociationObjectNotPersisted unless object.persisted?
          end
          self.target = object
          save!
          target
        end

        private

        def source_changed?
          read_source != identifier
        end
      end
    end
  end
end

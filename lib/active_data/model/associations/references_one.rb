require 'active_data/model/associations/base'

module ActiveData
  module Model
    module Associations
      class ReferencesOne < Base
        def save
          if target.present? && !target.marked_for_destruction?
            write_source identifier
          else
            write_source nil
          end
          true
        end
        alias_method :save!, :save

        def target= object
          loaded!
          @target = object
        end

        def target
          return @target if loaded?
          self.target = read_source && scope.first
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

        def scope
          reflection.klass.where(reflection.association_primary_key => read_source)
        end

        private

        def identifier
          target.try(reflection.association_primary_key)
        end

        def source_changed?
          read_source != identifier
        end
      end
    end
  end
end

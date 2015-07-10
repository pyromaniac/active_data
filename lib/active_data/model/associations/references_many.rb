require 'active_data/model/associations/base'
require 'active_data/model/associations/collection_proxy'

module ActiveData
  module Model
    module Associations
      class ReferencesMany < Base

        def save
          present_keys = target.reject { |t| t.marked_for_destruction? }.map(&reflection.association_primary_key).uniq
          write_source(present_keys)
          true
        end
        alias_method :save!, :save

        def target= object
          loaded!
          @target = object.to_a
        end

        def target
          return @target if loaded?
          self.target = read_source.present? ? scope.to_a : []
        end

        def reader force_reload = false
          reload if force_reload || source_changed?
          @proxy ||= CollectionProxy.new self
        end

        def replace objects
          transaction do
            clear
            append objects
          end
        end
        alias_method :writer, :replace

        def concat(*objects)
          append objects.flatten
          reader
        end

        def clear
          write_source([])
          reload.empty?
        end

        def scope
          reflection.klass.where(reflection.association_primary_key => read_source)
        end

        private

        def append objects
          objects.each do |object|
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
            raise AssociationObjectNotPersisted unless object.persisted?
            target[target.size] = object
            save
          end
          target
        end

        def identifiers
          target.map(&reflection.association_primary_key)
        end

        def source_changed?
          read_source != identifiers
        end
      end
    end
  end
end

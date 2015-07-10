require 'active_data/model/associations/base'
require 'active_data/model/associations/referenced_collection_proxy'

module ActiveData
  module Model
    module Associations
      class ReferencesMany < Base

        def save
          return false unless target.all?(&:persisted?)
          present_keys = target.reject { |t| t.marked_for_destruction? }.map(&reflection.primary_key)
          write_source(present_keys)
          true
        end

        def save!
          save or raise AssociationObjectNotPersisted
        end

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
          @proxy ||= ReferencedCollectionProxy.new self
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
          reflection.klass.where(reflection.primary_key => read_source)
        end

        private

        def append objects
          objects.each do |object|
            next if target.include?(object)
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
            target[target.size] = object
            save!
          end
          target
        end

        def identifiers
          target.map(&reflection.primary_key)
        end

        def source_changed?
          read_source != identifiers
        end
      end
    end
  end
end

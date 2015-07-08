require 'active_data/model/associations/base'

module ActiveData
  module Model
    module Associations
      class ReferencesOne < Base
        def save
          target ? (target.marked_for_destruction? ? write_source(nil) : write_source(target)) : write_source(nil)
        end
        alias_method :save!, :save

        def target= object
          loaded!
          @target = object
        end

        def target
          return @target if loaded?
          self.target = read_source
        end

        def reader force_reload = false
          reload if force_reload
          target
        end

        def writer object
          replace object
        end

        def replace object
          if object.nil?
            self.target = nil
          else
            raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object.is_a?(reflection.klass)
            raise AssociationObjectNotPersisted unless object.persisted?
            self.target = object
          end

          save! if owner.persisted?
          target
        end
      end
    end
  end
end

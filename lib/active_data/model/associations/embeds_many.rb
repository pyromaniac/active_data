module ActiveData
  module Model
    module Associations
      class EmbedsMany < Base
        class Proxy < Array
          delegate :build, :create, :create!, :reload, :concat, to: :@association
          alias_method :<<, :concat
          alias_method :push, :concat

          def initialize(data, association)
            @association = association
            super(data)
          end
        end

        def build attributes = {}
          push_object(reflection.klass.new(attributes))
        end

        def create attributes = {}
          build(attributes).tap(&:save)
        end

        def create! attributes = {}
          build(attributes).tap(&:save!)
        end

        def reload
          @target = Proxy.new load_target!, self
        end

        def clear
          transaction { reader.all?(&:destroy!) } rescue ActiveData::ObjectNotDestroyed
          reload.empty?
        end

        def reader force_reload = false
          if force_reload
            reload
          else
            @target ||= Proxy.new load_target!, self
          end
        end

        def writer values
          transaction do
            reader.map(&:destroy!)
            concat_objects(values) or raise ActiveData::AssociationNotSaved
          end
          reload
        end

        def concat *objects
          concat_objects objects.flatten
        end

      private

        def read_source
          super || []
        end

        def concat_objects objects
          objects.each { |object| push_object object }
          result = objects.all?(&:save)
          result ? reader : false
        end

        def push_object object
          raise AssociationTypeMismatch.new(reflection.klass, object.class) unless object && object.is_a?(reflection.klass)
          setup_performers! object
          reader[reader.size] = object
        end

        def load_target!
          data = read_source
          objects = data ? reflection.klass.instantiate_collection(data) : []
          objects.each { |object| setup_performers! object }
          objects
        end

        def setup_performers! object
          association = self

          object.define_create do
            data = association.send(:read_source)
            index = association.reader.select do |object|
              object.persisted? || object === self
            end.index { |object| object === self }

            data.insert(index, attributes)
            association.send(:write_source, data)
          end

          object.define_update do
            data = association.send(:read_source)
            index = association.reader.select(&:persisted?).index { |object| object === self }

            data[index] = attributes
            association.send(:write_source, data)
          end

          object.define_destroy do
            data = association.send(:read_source)
            index = association.reader.select(&:persisted?).index { |object| object === self }

            data.delete_at(index) if index
            association.send(:write_source, data)
          end
        end
      end
    end
  end
end

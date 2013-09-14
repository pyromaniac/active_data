require 'active_data/model/associations/reflections/base'
require 'active_data/model/associations/reflections/embeds_many'
require 'active_data/model/associations/reflections/embeds_one'

module ActiveData
  module Model
    module Associations
      extend ActiveSupport::Concern

      included do
        class_attribute :_reflections, instance_reader: false, instance_writer: false
        self._reflections = {}

        { embeds_many: Reflections::EmbedsMany, embeds_one: Reflections::EmbedsOne }.each do |(name, association_class)|
          define_singleton_method name do |*args|
            association = association_class.new *args
            association.define_accessor self
            self._reflections = _reflections.merge(association.name => association)
          end
        end
      end

      module ClassMethods
        def reflect_on_association name
          _reflections[name.to_sym]
        end

        def reflections
          _reflections
        end
      end

      def == other
        super(other) && self.class.reflections.keys.all? do |association|
          send(association) == other.send(association)
        end
      end

    end
  end
end
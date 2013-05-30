require 'active_data/model/associations/association'
require 'active_data/model/associations/embeds_many'
require 'active_data/model/associations/embeds_one'

module ActiveData
  module Model
    module Associations
      extend ActiveSupport::Concern

      included do
        cattr_accessor :_associations
        self._associations = {}

        { embeds_many: EmbedsMany, embeds_one: EmbedsOne }.each do |(name, association_class)|
          define_singleton_method name do |*args|
            association = association_class.new *args
            association.define_accessor self
            self._associations = _associations.merge!(association.name => association)
          end
        end
      end

      module ClassMethods

        def reflect_on_association name
          _associations[name.to_s]
        end

        def associations
          _associations
        end

        def association_names
          _associations.keys
        end
      end

      def == other
        super(other) && self.class.association_names.all? do |association|
          send(association) == other.send(association)
        end
      end

    end
  end
end
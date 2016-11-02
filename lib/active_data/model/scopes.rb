module ActiveData
  module Model
    module Scopes
      extend ActiveSupport::Concern

      included do
        class_attribute :_scope_base
        scopify
      end

      module ScopeProxy
        extend ActiveSupport::Concern

        def self.for(model)
          klass = Class.new(model._scope_base) do
            include ActiveData::Model::Scopes::ScopeProxy
          end
          klass.define_singleton_method(:_scope_model) { model }
          model.const_set('ScopeProxy', klass)
        end

        included do
          def initialize(source = nil, trust = false)
            source ||= self.class.superclass.new

            unless trust && source.is_a?(self.class)
              source.each do |entity|
                raise AssociationTypeMismatch.new(self.class._scope_model, entity.class) unless entity.is_a?(self.class._scope_model)
              end
            end

            super source
          end
        end

        def respond_to_missing?(method, _)
          super || self.class._scope_model.respond_to?(method)
        end

        def method_missing(method, *args, &block)
          with_scope do
            model = self.class._scope_model
            if model.respond_to?(method)
              self.class._scope_model.public_send(method, *args, &block)
            else
              super
            end
          end
        end

        def with_scope
          previous_scope = self.class._scope_model.current_scope
          self.class._scope_model.current_scope = self
          result = yield
          self.class._scope_model.current_scope = previous_scope
          result
        end
      end

      module ClassMethods
        def scopify(scope_base = Array)
          self._scope_base = scope_base
        end

        def scope_class
          @scope_class ||= ActiveData::Model::Scopes::ScopeProxy.for(self)
        end

        def scope(*args)
          if args.empty?
            current_scope
          else
            scope_class.new(*args)
          end
        end

        def current_scope=(value)
          @current_scope = value
        end

        def current_scope
          @current_scope ||= scope_class.new
        end
      end
    end
  end
end

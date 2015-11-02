module ActiveData
  module Model
    module Dirty
      extend ActiveSupport::Concern

      ::Module.class_eval do
        alias_method :unconcerned_append_features, :append_features
      end

      DIRTY_CLONE = ActiveModel::Dirty.clone
      DIRTY_CLONE.class_eval do
        def self.append_features(base)
          unconcerned_append_features(base)
        end
        def self.included(base)
        end
      end

      included do
        include DIRTY_CLONE

        unless method_defined?(:set_attribute_was)
          def set_attribute_was(attr, old_value)
            changed_attributes[attr] = old_value
          end
          private :set_attribute_was
        end

        attribute_names(false).each do |name|
          define_dirty name, generated_attributes_methods
        end
        _attribute_aliases.keys.each do |name|
          define_dirty name, generated_attributes_methods
        end
      end

      module ClassMethods
        def define_dirty method, target = self
          reflection = reflect_on_attribute(method)
          name = reflection ? reflection.name : method

          %w[changed? change will_change! was
             previously_changed? previous_change].each do |suffix|
            target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method}_#{suffix}
                attribute_#{suffix} '#{name}'
              end
            RUBY
          end

          target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def restore_#{method}!
              restore_attribute! '#{name}'
            end
          RUBY
        end

        def dirty?
          true
        end
      end
    end
  end
end

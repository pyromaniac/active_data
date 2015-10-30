module ActiveData
  module Model
    module Dirty
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Dirty

        unless method_defined?(:set_attribute_was)
          def set_attribute_was(attr, old_value)
            changed_attributes[attr] = old_value
          end
          private :set_attribute_was
        end
      end
    end
  end
end

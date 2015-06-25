module ActiveData
  module Model
    module Conventions
      extend ActiveSupport::Concern

      included do
        self.include_root_in_json = ActiveData.include_root_in_json
      end

      def persisted?
        false
      end

      def new_record?
        !persisted?
      end
      alias_method :new_object?, :new_record?

      module ClassMethods
        def i18n_scope
          ActiveData.i18n_scope
        end

        def to_ary
          nil
        end
      end
    end
  end
end

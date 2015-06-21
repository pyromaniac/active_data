module ActiveData
  module Model
    module Conventions
      extend ActiveSupport::Concern

      def errors
        @errors ||= ActiveModel::Errors.new(self)
      end

      def persisted?
        false
      end

      def new_record?
        !persisted?
      end

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

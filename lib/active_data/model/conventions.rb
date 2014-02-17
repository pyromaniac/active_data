module ActiveData
  module Model
    module Conventions
      def errors
        @errors ||= ActiveModel::Errors.new(self)
      end

      def persisted?
        @persisted
      end

      def destroyed?
        @destroyed
      end

      def freeze
        @attributes = @attributes.clone.freeze
        self
      end

      def frozen?
        @attributes.frozen?
      end

      def mark_for_destruction
        @marked_for_destruction = true
      end

      def marked_for_destruction?
        @marked_for_destruction
      end
    end
  end
end

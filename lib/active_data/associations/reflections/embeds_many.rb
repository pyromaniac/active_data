module ActiveData
  module Associations
    module Reflections
      class EmbedsMany < Base

        def collection?
          true
        end

        def define_reader target
          target.class_eval <<-EOS
            def #{name}
              @#{name} ||= begin
                association = self.class.reflect_on_association('#{name}')
                association.klass.collection
              end
            end
          EOS
        end

        def define_writer target
          target.class_eval <<-EOS
            def #{name}= value
              association = self.class.reflect_on_association('#{name}')
              @#{name} = association.klass.collection(value)
            end
          EOS
        end

      end
    end
  end
end

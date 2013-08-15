module ActiveData
  module Model
    module Associations
      class EmbedsOne < Association

        def collection?
          false
        end

        def define_reader target
          target.class_eval <<-EOS
            def #{name}
              @#{name}
            end
          EOS
        end

        def define_writer target
          target.class_eval <<-EOS
            def #{name}= value
              association = self.class.reflect_on_association('#{name}')
              if value.nil? || value.is_a?(association.klass)
                @#{name} = value
              else
                raise IncorrectEntity.new(association.klass, value.class)
              end
            end
          EOS
        end

      end
    end
  end
end
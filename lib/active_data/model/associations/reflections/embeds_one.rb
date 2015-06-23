require 'active_data/model/associations/reflections/base'

module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsOne < Base
          def macro
            :embeds_one
          end

          def collection?
            false
          end

          def association_class
            ActiveData::Model::Associations::EmbedsOne
          end

        private

          def define_methods!
            owner.class_eval <<-EOS
              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end

              def build_#{name} attributes = {}
                association(:#{name}).build(attributes)
              end

              def create_#{name} attributes = {}
                association(:#{name}).create(attributes)
              end

              def create_#{name}! attributes = {}
                association(:#{name}).create!(attributes)
              end
            EOS
          end
        end
      end
    end
  end
end

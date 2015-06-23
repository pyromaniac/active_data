require 'active_data/model/associations/reflections/base'

module ActiveData
  module Model
    module Associations
      module Reflections
        class EmbedsMany < Base
          def macro
            :embeds_many
          end

          def collection?
            true
          end

          def association_class
            ActiveData::Model::Associations::EmbedsMany
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
            EOS
          end
        end
      end
    end
  end
end

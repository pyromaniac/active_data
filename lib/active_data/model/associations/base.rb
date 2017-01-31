module ActiveData
  module Model
    module Associations
      class Base
        attr_accessor :owner, :reflection
        delegate :macro, :collection?, to: :reflection

        def initialize(owner, reflection)
          @owner = owner
          @reflection = reflection
          @evar_loaded = owner.persisted?
          reset
        end

        def reset
          @loaded = false
          @target = nil
        end

        def evar_loaded?
          !!@evar_loaded
        end

        def loaded?
          !!@loaded
        end

        def loaded!
          @evar_loaded = true
          @loaded = true
        end

        def target
          return @target if loaded?
          self.target = load_target
        end

        def reload
          reset
          target
        end

        def apply_changes!
          apply_changes or raise ActiveData::AssociationChangesNotApplied
        end

        def callback(name, object)
          evaluator = reflection.options[name]
          return true unless evaluator

          if evaluator.is_a?(Proc)
            if evaluator.arity == 1
              owner.instance_exec(object, &evaluator)
            else
              evaluator.call(owner, object)
            end
          else
            owner.send(evaluator, object)
          end
        end

        def transaction
          data = read_source.deep_dup
          yield
        rescue StandardError => e
          write_source data
          reload
          raise e
        end

        def inspect
          "#<#{reflection.macro.to_s.camelize} #{target.inspect.truncate(50, omission: collection? ? '...]' : '...')}>"
        end

      private

        def read_source
          reflection.read_source owner
        end

        def write_source(value)
          reflection.write_source owner, value
        end

        def target_for_inspect
          if value.length > 50
            "#{value[0..50]}...".inspect
          else
            value.inspect
          end
        end
      end
    end
  end
end

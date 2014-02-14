module ActiveData
  module ActiveRecord
    module Associations
      extend ActiveSupport::Concern

      included do
        {
          embeds_many: ActiveData::Model::Associations::Reflections::EmbedsMany,
          embeds_one: ActiveData::Model::Associations::Reflections::EmbedsOne
        }.each do |(name, reflection_class)|
          define_singleton_method name do |*args|
            reflection = reflection_class.new *args
            reflection.define_methods self
            self.reflections = reflections.merge(reflection.name => reflection)
          end
        end
      end
    end
  end
end

module ActiveData
  module Model
    module Extensions
      module TrueClass
        def demodelize
          1
        end
      end
    end
  end
end

TrueClass.send :include, ActiveData::Model::Extensions::TrueClass

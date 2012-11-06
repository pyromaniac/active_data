module ActiveData
  module Model
    module Extensions
      module FalseClass
        def demodelize
          1
        end
      end
    end
  end
end

FalseClass.send :include, ActiveData::Model::Extensions::FalseClass
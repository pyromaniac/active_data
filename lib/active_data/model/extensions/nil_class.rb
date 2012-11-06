module ActiveData
  module Model
    module Extensions
      module NilClass
        def demodelize
          ''
        end
      end
    end
  end
end

NilClass.send :include, ActiveData::Model::Extensions::NilClass
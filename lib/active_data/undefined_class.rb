require 'singleton'

module ActiveData
  class UndefinedClass
    include Singleton
  end

  UNDEFINED = UndefinedClass.instance.freeze
end

unless defined?(Boolean)
  class Boolean; end
end

begin
  require 'uuidtools'
rescue LoadError
else
  class ActiveData::UUID < UUIDTools::UUID
  end
end

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].each { |f| require f }

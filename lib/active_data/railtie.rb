module ActiveData
  class Railtie < Rails::Railtie
    initializer 'active_data.logger', after: 'active_record.logger' do
      ActiveSupport.on_load(:active_record)  { ActiveData.logger ||= ActiveRecord::Base.logger }
    end
  end
end

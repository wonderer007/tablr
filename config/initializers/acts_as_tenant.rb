SET_TENANT_PROC = lambda do
  if defined?(Rails::Console)
    puts "> ActsAsTenant.current_tenant = Place.first"
    ActsAsTenant.current_tenant = Place.last
  end
end

Rails.application.configure do
  if Rails.env.development?
    # Set the tenant to the first account in development on load
    config.after_initialize do
      SET_TENANT_PROC.call
    end

    # Reset the tenant after calling 'reload!' in the console
    ActiveSupport::Reloader.to_complete do
      SET_TENANT_PROC.call
    end
  end
end

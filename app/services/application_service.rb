class ApplicationService
  def self.call(*args)
    current_tenant = Business.find(args.first[:business_id])

    ActsAsTenant.with_tenant(current_tenant) do
      new(**args.first).call
    end
  end
end

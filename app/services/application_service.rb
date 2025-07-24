class ApplicationService
  def self.call(*args)
    current_tenant = Place.find(args.first[:place_id])

    ActsAsTenant.with_tenant(current_tenant) do
      new(**args.first).call
    end
  end
end

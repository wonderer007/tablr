module OnboardingHelper
  def integration_bg_class(integration_id)
    classes = {
      google_maps: 'bg-gradient-to-br from-[#4285F4] to-[#34A853] text-white',
      yelp: 'bg-gradient-to-br from-[#FF1A1A] to-[#c41200] text-white',
      tripadvisor: 'bg-gradient-to-br from-[#00b67a] to-[#00857c] text-white',
      trustpilot: 'bg-gradient-to-br from-[#00b67a] to-[#00857c] text-white'
    }
    classes[integration_id.to_sym] || 'bg-slate-100 text-slate-600'
  end
end


class Business < ApplicationRecord
  ACTOR_ID = '2Mdma1N6Fd0y3QEjR'

  self.inheritance_column = nil
  # URL is required only after onboarding is completed
  validates :url, uniqueness: { scope: :test }, allow_nil: true
  validates :url, presence: true, if: :onboarding_completed?

  has_many :reviews
  has_many :users
  has_many :notifications
  has_many :inference_requests

  has_many :complains, through: :reviews
  has_many :suggestions, through: :reviews

  enum :type, [:restaurant, :hotel, :others], default: :restaurant
  enum :status, [:created, :syncing_place, :synced_place, :syncing_reviews, :synced_reviews, :failed]
  enum :business_type, {
    google_place: 'google_place',
    amazon_store: 'amazon_store',
    shopify_store: 'shopify_store',
    android_app: 'android_app',
    ios_app: 'ios_app'
  }, default: 'google_place'
  enum :plan, { free: 'free', pro: 'pro' }, default: 'free'

  # Plan features
  PLAN_FEATURES = {
    free: {
      name: 'Free',
      price: '$0',
      period: 'one-time',
      features: [
        'Up to 200 reviews',
        'Basic complaint extraction',
        'Basic suggestion mining',
        '1 platform integration'
      ],
      limitations: [
        'Limited to 200 reviews',
        'One-time analysis only'
      ]
    },
    pro: {
      name: 'Pro',
      price: '$10',
      period: 'per month',
      features: [
        'Up to 3,000 reviews',
        'AI complaint extraction',
        'AI suggestion mining',
        'Weekly & monthly reports',
        'All platform integrations',
        '6 months historic data',
        'Priority support'
      ],
      limitations: []
    }
  }.freeze

  # Available integrations for onboarding
  AVAILABLE_INTEGRATIONS = [
    { id: :google_maps, name: 'Google Maps', icon: 'google_maps', url_label: 'Google Place URL', placeholder: 'https://maps.google.com/...', coming_soon: false },
    { id: :yelp, name: 'Yelp', icon: 'yelp', url_label: 'Yelp Profile URL', placeholder: 'https://yelp.com/biz/...', coming_soon: true },
    { id: :tripadvisor, name: 'Tripadvisor', icon: 'tripadvisor', url_label: 'Tripadvisor URL', placeholder: 'https://tripadvisor.com/...', coming_soon: true },
    { id: :trustpilot, name: 'Trustpilot', icon: 'trustpilot', url_label: 'Trustpilot URL', placeholder: 'https://trustpilot.com/...', coming_soon: true }
  ].freeze

  INTEGRATION_TO_BUSINESS_TYPE = {
    google_maps: :google_place,
    yelp: :google_place,
    tripadvisor: :google_place,
    trustpilot: :google_place,
    amazon_store: :amazon_store,
    shopify: :shopify_store,
    play_store: :android_app,
    app_store: :ios_app
  }.freeze

  def needs_onboarding?
    !onboarding_completed?
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name place_actor_run_id review_actor_run_id status url rating id first_inference_completed test business_type]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  # Check if business needs to complete payment for Pro plan
  def needs_payment?
    pro? && !payment_approved?
  end

  # Check if business can proceed (Free plan or paid Pro)
  def can_access?
    free? || payment_approved?
  end

  def food_rating
    return 0 if reviews.none?

    reviews.where.not(food_rating: nil).average(:food_rating).round(1)
  end

  def service_rating
    return 0 if reviews.none?

    reviews.where.not(service_rating: nil).average(:service_rating).round(1)
  end

  def atmosphere_rating
    return 0 if reviews.none?

    reviews.where.not(atmosphere_rating: nil).average(:atmosphere_rating).round(1)
  end

  def address
    data&.dig('address')
  end
end


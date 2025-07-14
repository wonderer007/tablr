class ReviewsController < ApplicationController
  layout 'dashboard'

  def index
    place = Place.first
    @reviews = place.reviews.order(published_at: :desc).limit(50)
  end
end

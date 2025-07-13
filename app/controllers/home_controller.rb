class HomeController < ApplicationController
  def dashboard
    @place = Place.first
  end
end

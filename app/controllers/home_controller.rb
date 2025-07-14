class HomeController < ApplicationController
  layout 'dashboard'
  
  def dashboard
    @place = Place.first
  end
end

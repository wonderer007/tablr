class DemoRequestsController < ApplicationController
  def new
    @demo_request = DemoRequest.new
  end

  def create
    @demo_request = DemoRequest.new(demo_request_params)
    
    if @demo_request.save
      redirect_to thank_you_demo_requests_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
    # Thank you page with Calendly link
  end

  private

  def demo_request_params
    params.require(:demo_request).permit(:first_name, :last_name, :email, :restaurant_name, :google_map_url)
  end
end

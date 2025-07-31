class PaymentController < ApplicationController
  before_action :authenticate_user!
  layout 'auth'

  def processing
    if current_user.payment_approved?
      redirect_to dashboard_path and return
    end

    @payment_url = ENV['PAYMENT_URL']
  end
end
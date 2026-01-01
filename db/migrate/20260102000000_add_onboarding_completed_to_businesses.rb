# frozen_string_literal: true

class AddOnboardingCompletedToBusinesses < ActiveRecord::Migration[7.2]
  def change
    add_column :businesses, :onboarding_completed, :boolean, default: false
  end
end


# frozen_string_literal: true

class AddPlanToBusinesses < ActiveRecord::Migration[7.2]
  def change
    add_column :businesses, :plan, :string, default: 'free', null: false
    add_index :businesses, :plan
  end
end


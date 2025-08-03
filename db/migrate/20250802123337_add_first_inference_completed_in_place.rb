class AddFirstInferenceCompletedInPlace < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :first_inference_completed, :boolean, default: false
  end
end

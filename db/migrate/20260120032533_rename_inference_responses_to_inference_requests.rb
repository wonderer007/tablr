class RenameInferenceResponsesToInferenceRequests < ActiveRecord::Migration[7.2]
  def change
    rename_table :inference_responses, :inference_requests

    add_column :inference_requests, :input_token_count, :integer
    add_column :inference_requests, :output_token_count, :integer
  end
end


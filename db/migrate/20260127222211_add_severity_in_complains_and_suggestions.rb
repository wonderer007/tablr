class AddSeverityInComplainsAndSuggestions < ActiveRecord::Migration[7.2]
  def change
    add_column :complains, :severity, :integer
    add_column :suggestions, :severity, :integer
  end
end

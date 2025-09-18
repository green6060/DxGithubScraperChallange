class CreateRepositories < ActiveRecord::Migration[7.2]
  def change
    create_table :repositories do |t|
      t.string :github_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :url, null: false
      t.boolean :is_private, default: false
      t.boolean :is_archived, default: false
      t.timestamps
    end
  end
end

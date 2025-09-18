class CreatePullRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :pull_requests do |t|
      t.integer :number, null: false
      t.string :github_id, null: false, index: { unique: true }
      t.string :title, null: false
      t.references :author, null: false
      t.datetime :closed_at
      t.datetime :merged_at
      t.integer :additions, default: 0
      t.integer :deletions, default: 0
      t.integer :changed_files, default: 0
      t.integer :commit_count, default: 0
      t.timestamps
    end
  end
end

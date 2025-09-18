class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :pull_request, null: false
      t.string :github_id, null: false, index: { unique: true }
      t.references :reviewer, null: false
      t.string :state, null: false
      t.datetime :submitted_at
      t.timestamps
    end
  end
end

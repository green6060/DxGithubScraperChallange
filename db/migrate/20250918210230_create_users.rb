class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :github_id, null: false, index: { unique: true }
      t.string :login, null: false
      t.timestamps
    end
  end
end

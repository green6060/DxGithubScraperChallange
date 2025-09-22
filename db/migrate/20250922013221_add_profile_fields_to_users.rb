class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
    add_column :users, :email, :string
    add_column :users, :bio, :text
    add_column :users, :company, :string
    add_column :users, :location, :string
    add_column :users, :blog, :string
    add_column :users, :twitter_username, :string
    add_column :users, :public_repos, :integer
    add_column :users, :public_gists, :integer
    add_column :users, :followers, :integer
    add_column :users, :following, :integer
    add_column :users, :github_created_at, :datetime
    add_column :users, :github_updated_at, :datetime
  end
end

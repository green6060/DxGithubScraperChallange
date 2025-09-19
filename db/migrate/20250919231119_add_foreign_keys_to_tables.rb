class AddForeignKeysToTables < ActiveRecord::Migration[7.2]
  def change
    # Add foreign key from pull_requests to repositories
    add_foreign_key :pull_requests, :repositories
    
    # Add foreign key from pull_requests to users (author)
    add_foreign_key :pull_requests, :users, column: :author_id
    
    # Add foreign key from reviews to pull_requests
    add_foreign_key :reviews, :pull_requests
    
    # Add foreign key from reviews to users (reviewer)
    add_foreign_key :reviews, :users, column: :reviewer_id
  end
end

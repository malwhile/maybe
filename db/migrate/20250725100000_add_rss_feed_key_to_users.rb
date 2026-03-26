class AddRssFeedKeyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :rss_feed_key, :string
    add_index :users, :rss_feed_key, unique: true, where: "rss_feed_key IS NOT NULL"
  end
end

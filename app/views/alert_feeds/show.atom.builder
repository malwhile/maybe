atom_feed language: "en-US" do |feed|
  feed.title "Maybe Finance Alerts"
  feed.updated @alerts.first&.created_at || Time.current

  @alerts.each do |alert|
    feed.entry alert, url: root_url, updated: alert.updated_at, published: alert.created_at do |entry|
      entry.title alert.title
      entry.content alert.description, type: "text"
    end
  end
end

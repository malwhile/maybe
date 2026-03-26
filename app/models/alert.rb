class Alert < ApplicationRecord
  TYPES = %w[budget_exceeded large_transaction rule_applied].freeze

  belongs_to :family
  belongs_to :alertable, polymorphic: true, optional: true

  validates :alert_type, presence: true, inclusion: { in: TYPES }

  scope :recent, -> { order(created_at: :desc).limit(100) }

  def self.record_budget_exceeded!(family:, budget_category:, metadata: {})
    safe_find_or_create!(family, "budget_exceeded", budget_category, metadata)
  end

  def self.record_large_transaction!(family:, entry:, metadata: {})
    safe_find_or_create!(family, "large_transaction", entry, metadata)
  end

  def self.record_rule_applied!(family:, entry:, rule:, metadata: {})
    safe_find_or_create!(family, "rule_applied", entry,
      metadata.merge(rule_id: rule.id, rule_name: rule.name))
  end

  def title
    case alert_type
    when "budget_exceeded"   then "Budget Exceeded: #{metadata["category_name"]}"
    when "large_transaction" then "Large Transaction: #{metadata["entry_name"]}"
    when "rule_applied"      then "Rule Applied: #{metadata["rule_name"]}"
    end
  end

  def description
    case alert_type
    when "budget_exceeded"
      "#{metadata["category_name"]} spent #{metadata["actual_spending"]} of #{metadata["budgeted_spending"]} budget"
    when "large_transaction"
      "\"#{metadata["entry_name"]}\" of #{metadata["amount"]} on #{metadata["date"]} exceeded threshold of #{metadata["threshold"]}"
    when "rule_applied"
      "Rule \"#{metadata["rule_name"]}\" was applied to \"#{metadata["entry_name"]}\""
    end
  end

  private

    def self.safe_find_or_create!(family, type, alertable, metadata)
      find_or_create_by(family: family, alert_type: type, alertable: alertable) do |a|
        a.metadata = metadata
      end
    rescue ActiveRecord::RecordNotUnique
      find_by(family: family, alert_type: type, alertable: alertable)
    end
end

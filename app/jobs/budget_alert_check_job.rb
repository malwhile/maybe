class BudgetAlertCheckJob < ApplicationJob
  queue_as :default

  def perform(family_id = nil)
    families = family_id ? Family.where(id: family_id) : Family.all
    families.each { |f| check_family(f) }
  end

  private

    def check_family(family)
      # Don't bootstrap — only check families actively using budgets
      budget = family.budgets.find_by(start_date: Date.current.beginning_of_month)
      return unless budget

      budget.budget_categories.each do |bc|
        next unless bc.budgeted_spending > 0
        next unless bc.available_to_spend.negative?

        Alert.record_budget_exceeded!(
          family: family,
          budget_category: bc,
          metadata: {
            category_name: bc.category&.name || "Uncategorized",
            budgeted_spending: bc.budgeted_spending.to_s,
            actual_spending: bc.actual_spending.to_s,
            currency: bc.currency,
            budget_month: budget.start_date.strftime("%B %Y")
          }
        )
      end
    end
end

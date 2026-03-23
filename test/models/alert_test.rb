require "test_helper"

class AlertTest < ActiveSupport::TestCase
  def setup
    @family = families(:one)
    @category = categories(:one)
    @budget = Budget.find_or_bootstrap(@family, start_date: Date.current)
    @budget_category = @budget.budget_categories.find_or_create_by(category: @category)
    @account = accounts(:one)
    @entry = entries(:one)
  end

  test "record_budget_exceeded! creates an alert" do
    assert_difference "Alert.count" do
      Alert.record_budget_exceeded!(
        family: @family,
        budget_category: @budget_category,
        metadata: { category_name: "Test" }
      )
    end
  end

  test "record_budget_exceeded! does not create duplicate for same category" do
    Alert.record_budget_exceeded!(
      family: @family,
      budget_category: @budget_category,
      metadata: { category_name: "Test" }
    )

    assert_no_difference "Alert.count" do
      Alert.record_budget_exceeded!(
        family: @family,
        budget_category: @budget_category,
        metadata: { category_name: "Test Updated" }
      )
    end
  end

  test "record_large_transaction! creates an alert" do
    assert_difference "Alert.count" do
      Alert.record_large_transaction!(
        family: @family,
        entry: @entry,
        metadata: { entry_name: "Test" }
      )
    end
  end

  test "record_large_transaction! does not create duplicate for same entry" do
    Alert.record_large_transaction!(
      family: @family,
      entry: @entry,
      metadata: { entry_name: "Test" }
    )

    assert_no_difference "Alert.count" do
      Alert.record_large_transaction!(
        family: @family,
        entry: @entry,
        metadata: { entry_name: "Test Updated" }
      )
    end
  end

  test "record_rule_applied! creates an alert" do
    rule = rules(:one)
    assert_difference "Alert.count" do
      Alert.record_rule_applied!(
        family: @family,
        entry: @entry,
        rule: rule,
        metadata: { rule_name: rule.name }
      )
    end
  end

  test "title returns correct string for budget_exceeded" do
    alert = Alert.create!(
      family: @family,
      alert_type: "budget_exceeded",
      alertable: @budget_category,
      metadata: { category_name: "Groceries" }
    )
    assert_equal "Budget Exceeded: Groceries", alert.title
  end

  test "title returns correct string for large_transaction" do
    alert = Alert.create!(
      family: @family,
      alert_type: "large_transaction",
      alertable: @entry,
      metadata: { entry_name: "Coffee" }
    )
    assert_equal "Large Transaction: Coffee", alert.title
  end

  test "title returns correct string for rule_applied" do
    alert = Alert.create!(
      family: @family,
      alert_type: "rule_applied",
      alertable: @entry,
      metadata: { rule_name: "Auto Categorize" }
    )
    assert_equal "Rule Applied: Auto Categorize", alert.title
  end

  test "description returns correct string for budget_exceeded" do
    alert = Alert.create!(
      family: @family,
      alert_type: "budget_exceeded",
      alertable: @budget_category,
      metadata: {
        category_name: "Groceries",
        actual_spending: "600.00",
        budgeted_spending: "500.00"
      }
    )
    assert_includes alert.description, "Groceries"
    assert_includes alert.description, "600.00"
    assert_includes alert.description, "500.00"
  end

  test "recent scope returns up to 100 alerts ordered by created_at desc" do
    11.times do
      Alert.create!(
        family: @family,
        alert_type: "budget_exceeded",
        alertable: @budget_category,
        metadata: {}
      )
      sleep 0.01 # small delay to ensure created_at differs
    end

    alerts = Alert.recent
    assert_equal 11, alerts.count
    assert alerts.first.created_at >= alerts.last.created_at
  end
end

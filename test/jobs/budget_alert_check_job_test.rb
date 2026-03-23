require "test_helper"

class BudgetAlertCheckJobTest < ActiveJob::TestCase
  def setup
    @family = families(:one)
    @category = categories(:one)
    @budget = Budget.find_or_bootstrap(@family, start_date: Date.current)
  end

  test "creates alert for over-budget category" do
    budget_category = @budget.budget_categories.find_or_create_by!(
      category: @category,
      budgeted_spending: 100
    )

    # Mock actual_spending to be greater than budgeted
    Budget.any_instance.stubs(:budget_category_actual_spending).returns(Money.new(150_00, "USD"))

    assert_difference "Alert.count" do
      BudgetAlertCheckJob.new.perform(@family.id)
    end

    alert = Alert.last
    assert_equal "budget_exceeded", alert.alert_type
    assert_equal budget_category, alert.alertable
  end

  test "does not create alert for under-budget category" do
    budget_category = @budget.budget_categories.find_or_create_by!(
      category: @category,
      budgeted_spending: 100
    )

    Budget.any_instance.stubs(:budget_category_actual_spending).returns(Money.new(50_00, "USD"))

    assert_no_difference "Alert.count" do
      BudgetAlertCheckJob.new.perform(@family.id)
    end
  end

  test "does not create alert for zero budgeted amount" do
    budget_category = @budget.budget_categories.find_or_create_by!(
      category: @category,
      budgeted_spending: 0
    )

    Budget.any_instance.stubs(:budget_category_actual_spending).returns(Money.new(150_00, "USD"))

    assert_no_difference "Alert.count" do
      BudgetAlertCheckJob.new.perform(@family.id)
    end
  end

  test "does not create duplicate alert for same category" do
    budget_category = @budget.budget_categories.find_or_create_by!(
      category: @category,
      budgeted_spending: 100
    )

    Budget.any_instance.stubs(:budget_category_actual_spending).returns(Money.new(150_00, "USD"))

    # First run
    BudgetAlertCheckJob.new.perform(@family.id)
    assert_equal 1, Alert.count

    # Second run
    assert_no_difference "Alert.count" do
      BudgetAlertCheckJob.new.perform(@family.id)
    end
  end

  test "performs for all families when no family_id provided" do
    family2 = families(:two)
    budget2 = Budget.find_or_bootstrap(family2, start_date: Date.current)

    @budget.budget_categories.find_or_create_by!(
      category: @category,
      budgeted_spending: 100
    )
    budget2.budget_categories.find_or_create_by!(
      category: @category,
      budgeted_spending: 50
    )

    Budget.any_instance.stubs(:budget_category_actual_spending).returns(Money.new(150_00, "USD"))

    assert_difference "Alert.count", 2 do
      BudgetAlertCheckJob.new.perform
    end
  end
end

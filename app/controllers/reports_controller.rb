class ReportsController < ApplicationController
  include Periodable

  def index
    @breadcrumbs = [ [ "Home", root_path ], [ "Reports", nil ] ]
  end

  def net_worth
    @balance_sheet = Current.family.balance_sheet
    @breadcrumbs = [ [ "Home", root_path ], [ "Reports", reports_path ], [ "Net Worth", nil ] ]
  end

  def balance_sheet
    @balance_sheet = Current.family.balance_sheet
    @breadcrumbs = [ [ "Home", root_path ], [ "Reports", reports_path ], [ "Balance Sheet", nil ] ]
  end

  def cashflow
    period_param = params[:period]
    @period = if period_param.present?
      begin
        Period.from_key(period_param)
      rescue Period::InvalidKeyError
        Period.last_30_days
      end
    else
      Period.last_30_days
    end

    family_currency = Current.family.currency
    income_totals = Current.family.income_statement.income_totals(period: @period)
    expense_totals = Current.family.income_statement.expense_totals(period: @period)

    @cashflow_sankey_data = build_cashflow_sankey_data(income_totals, expense_totals, family_currency)
    @breadcrumbs = [ [ "Home", root_path ], [ "Reports", reports_path ], [ "Cash Flow", nil ] ]
  end

  def net_income
    @view        = params[:view].presence_in(%w[totals breakdown]) || "breakdown"
    @account_ids = params[:account_ids].presence
    @accounts    = Current.family.accounts.order(:name)

    stmt = Current.family.income_statement
    @income_totals  = stmt.income_totals(period: @period, account_ids: @account_ids)
    @expense_totals = stmt.expense_totals(period: @period, account_ids: @account_ids)

    # Previous period for trend comparison
    days = (@period.end_date - @period.start_date).to_i + 1
    prev_period     = Period.new(start_date: @period.start_date - days, end_date: @period.start_date - 1)
    prev_income     = stmt.income_totals(period: prev_period, account_ids: @account_ids)
    prev_expense    = stmt.expense_totals(period: prev_period, account_ids: @account_ids)

    currency = Current.family.currency
    @income_trend  = Trend.new(current: Money.new(@income_totals.total, currency),
                                previous: Money.new(prev_income.total, currency),
                                favorable_direction: "up")
    @expense_trend = Trend.new(current: Money.new(@expense_totals.total, currency),
                                previous: Money.new(prev_expense.total, currency),
                                favorable_direction: "down")
    @net_trend     = Trend.new(current: Money.new(@income_totals.total - @expense_totals.total, currency),
                                previous: Money.new(prev_income.total - prev_expense.total, currency),
                                favorable_direction: "up")

    @breadcrumbs = [ [ "Home", root_path ], [ "Reports", reports_path ], [ "Net Income", nil ] ]
  end

  private
    def build_cashflow_sankey_data(income_totals, expense_totals, currency_symbol)
      nodes = []
      links = []
      node_indices = {}

      add_node = ->(unique_key, display_name, value, percentage, color) {
        node_indices[unique_key] ||= begin
          nodes << { name: display_name, value: value.to_f.round(2), percentage: percentage.to_f.round(1), color: color }
          nodes.size - 1
        end
      }

      total_income_val = income_totals.total.to_f.round(2)
      total_expense_val = expense_totals.total.to_f.round(2)

      cash_flow_idx = add_node.call("cash_flow_node", "Cash Flow", total_income_val, 0, "var(--color-success)")

      income_totals.category_totals.each do |ct|
        next if ct.category.parent_id.present?

        val = ct.total.to_f.round(2)
        next if val.zero?

        percentage_of_total_income = total_income_val.zero? ? 0 : (val / total_income_val * 100).round(1)

        node_display_name = ct.category.name
        node_color = ct.category.color.presence || Category::COLORS.sample

        current_cat_idx = add_node.call(
          "income_#{ct.category.id}",
          node_display_name,
          val,
          percentage_of_total_income,
          node_color
        )

        links << {
          source: current_cat_idx,
          target: cash_flow_idx,
          value: val,
          color: node_color,
          percentage: percentage_of_total_income
        }
      end

      expense_totals.category_totals.each do |ct|
        next if ct.category.parent_id.present?

        val = ct.total.to_f.round(2)
        next if val.zero?

        percentage_of_total_expense = total_expense_val.zero? ? 0 : (val / total_expense_val * 100).round(1)

        node_display_name = ct.category.name
        node_color = ct.category.color.presence || Category::UNCATEGORIZED_COLOR

        current_cat_idx = add_node.call(
          "expense_#{ct.category.id}",
          node_display_name,
          val,
          percentage_of_total_expense,
          node_color
        )

        links << {
          source: cash_flow_idx,
          target: current_cat_idx,
          value: val,
          color: node_color,
          percentage: percentage_of_total_expense
        }
      end

      leftover = (total_income_val - total_expense_val).round(2)
      if leftover.positive?
        percentage_of_total_income_for_surplus = total_income_val.zero? ? 0 : (leftover / total_income_val * 100).round(1)
        surplus_idx = add_node.call("surplus_node", "Surplus", leftover, percentage_of_total_income_for_surplus, "var(--color-success)")
        links << { source: cash_flow_idx, target: surplus_idx, value: leftover, color: "var(--color-success)", percentage: percentage_of_total_income_for_surplus }
      end

      if node_indices["cash_flow_node"]
        nodes[node_indices["cash_flow_node"]][:percentage] = 100.0
      end

      { nodes: nodes, links: links, currency_symbol: Money::Currency.new(currency_symbol).symbol }
    end
end

#!/bin/bash

set -e

echo "Creating GitHub issues for reports..."

# Main issue: Building Reports
gh issue create \
  --title "Feature: Build comprehensive financial reports" \
  --body "Implement a suite of financial reports to help users understand their financial health, spending patterns, and net worth trends. This epic tracks implementation of multiple report types including cash flow, income vs expenses, asset summaries, and more." \
  --label "enhancement"

echo "✓ Main reports feature issue created"

# Report 1: Cash Flow Report
gh issue create \
  --title "Report: Cash flow visualization" \
  --body "Display monthly or period-based cash flow showing total income, total expenses, and net cash flow. Include filters by date range and category. Visual representation with line/bar charts." \
  --label "enhancement"

echo "✓ Cash flow report issue created"

# Report 2: Net Income vs Expenses
gh issue create \
  --title "Report: Net income vs expenses" \
  --body "Compare total income against total expenses for selected period. Show breakdown by income sources and expense categories. Include trends and percentage changes." \
  --label "enhancement"

echo "✓ Net income vs expenses report issue created"

# Report 3: Total Assets
gh issue create \
  --title "Report: Total assets summary" \
  --body "Display total assets across all account types (checking, savings, investments, crypto, property, etc.). Show breakdown by account type with trends over time." \
  --label "enhancement"

echo "✓ Total assets report issue created"

# Report 4: Assets minus Debts (Net Worth)
gh issue create \
  --title "Report: Net worth (assets minus debts)" \
  --body "Show net worth calculation: total assets minus total liabilities (loans, credit cards, mortgages). Display historical net worth trend and contribution by account type." \
  --label "enhancement"

echo "✓ Net worth report issue created"

# Report 5: Expense breakdown by category
gh issue create \
  --title "Report: Expense breakdown by category" \
  --body "Visualize spending distribution across categories using pie/donut charts. Include ability to filter by date range, set category drill-downs, and compare periods." \
  --label "enhancement"

echo "✓ Expense breakdown report issue created"

# Report 6: Income sources breakdown
gh issue create \
  --title "Report: Income sources breakdown" \
  --body "Show all income sources and their relative contributions. Help users understand income diversification and trends for each source over time." \
  --label "enhancement"

echo "✓ Income sources report issue created"

# Report 7: Savings rate
gh issue create \
  --title "Report: Savings rate analysis" \
  --body "Calculate and display savings rate as percentage of income. Show historical trends and monthly/annual comparison. Include recommendations based on savings rate." \
  --label "enhancement"

echo "✓ Savings rate report issue created"

# Report 8: Net worth trends
gh issue create \
  --title "Report: Net worth trends over time" \
  --body "Display historical net worth as line chart showing wealth accumulation over time. Include ability to zoom, filter by date range, and identify major contributing factors." \
  --label "enhancement"

echo "✓ Net worth trends report issue created"

# Report 9: Budget vs actual
gh issue create \
  --title "Report: Budget vs actual spending" \
  --body "Compare planned budgets against actual spending by category. Show variance, help identify overspending areas, and display trends for budget planning." \
  --label "enhancement"

echo "✓ Budget vs actual report issue created"

# Report 10: Account balances by type
gh issue create \
  --title "Report: Account balances by type" \
  --body "Summary view of all accounts grouped by type (checking, savings, investment, loans, etc.) with current balances and trends. Quick snapshot of financial position." \
  --label "enhancement"

echo "✓ Account balances report issue created"

# Report 11: Investment performance
gh issue create \
  --title "Report: Investment performance and returns" \
  --body "Display investment portfolio performance including total return, YTD return, and individual holding performance. Include dividend income and asset allocation breakdown." \
  --label "enhancement"

echo "✓ Investment performance report issue created"

# Report 12: Debt payoff timeline
gh issue create \
  --title "Report: Debt payoff timeline projection" \
  --body "Project payoff dates for loans and credit cards based on current payment patterns. Help users understand when debts will be eliminated and savings potential." \
  --label "enhancement"

echo "✓ Debt payoff timeline report issue created"

# Report 13: Monthly/annual summaries
gh issue create \
  --title "Report: Monthly and annual spending summaries" \
  --body "Compare spending, income, and savings across months and years. Identify seasonal patterns and year-over-year trends for better financial planning." \
  --label "enhancement"

echo "✓ Monthly/annual summaries report issue created"

echo ""
echo "✓ All report issues created successfully!"
echo ""
echo "Run: gh issue list --limit 20"
echo "to verify all issues were created."

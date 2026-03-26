class Rule::Action < ApplicationRecord
  belongs_to :rule, touch: true

  validates :action_type, presence: true

  def apply(resource_scope, ignore_attribute_locks: false)
    executor.execute(resource_scope, value: value, ignore_attribute_locks: ignore_attribute_locks)

    # Emit rule_applied alerts for each transaction in the scope
    resource_scope.each do |txn|
      Alert.record_rule_applied!(
        family: rule.family,
        entry: txn.entry,
        rule: rule,
        metadata: {
          rule_name: rule.name,
          entry_name: txn.entry.name,
          action_type: action_type
        }
      )
    end
  end

  def options
    executor.options
  end

  def value_display
    if value.present?
      if options
        options.find { |option| option.last == value }&.first
      else
        ""
      end
    else
      ""
    end
  end

  def executor
    rule.registry.get_executor!(action_type)
  end
end

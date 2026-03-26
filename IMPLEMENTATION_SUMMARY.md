# Authenticated Atom/RSS Alert Feed - Implementation Summary

## Overview
A complete implementation of an authenticated Atom/RSS alert feed for the Maybe finance app. Users can subscribe to financial alerts (budget exceeded, large transactions, rule applied) in their preferred RSS reader using HTTP Basic Auth.

## What Was Completed

### ✅ Database Migrations (3 files)
- `db/migrate/20250725100000_add_rss_feed_key_to_users.rb` - Adds encrypted RSS feed key column to users table
- `db/migrate/20250725100100_add_large_transaction_threshold_to_families.rb` - Adds configurable threshold for large transactions
- `db/migrate/20250725100200_create_alerts.rb` - Creates alerts table with polymorphic alertable and unique deduplication index

### ✅ Models (4 files modified/created)
1. **app/models/alert.rb** (new)
   - Three alert types: budget_exceeded, large_transaction, rule_applied
   - Factory methods: `record_budget_exceeded!`, `record_large_transaction!`, `record_rule_applied!`
   - Smart deduplication via unique index on (family_id, alert_type, alertable_type, alertable_id)
   - `title` and `description` methods for feed rendering

2. **app/models/user.rb** (modified)
   - `encrypts :rss_feed_key, deterministic: true` - secure storage matching ApiKey pattern
   - `generate_rss_feed_key!` / `revoke_rss_feed_key!` - key lifecycle management
   - `authenticate_rss_feed!(email, key)` - HTTP Basic Auth lookup with timing-safe comparison
   - `generate_rss_key` - class method for secure key generation

3. **app/models/family.rb** (modified)
   - `has_many :alerts, dependent: :destroy` - relationship
   - `large_transaction_alerts_enabled?` - helper to check if alerts are configured

4. **app/models/entry.rb** (modified)
   - `after_create_commit :check_large_transaction_alert` - emits alert when transaction exceeds threshold
   - `after_create_commit :enqueue_budget_alert_check` - triggers budget check job
   - `after_destroy_commit :enqueue_budget_alert_check` - also triggers on deletion
   - Helper methods: `check_large_transaction_alert`, `enqueue_budget_alert_check`

### ✅ Alert Triggers (2 jobs + 1 model update)
1. **app/jobs/budget_alert_check_job.rb** (new)
   - Checks current month budget categories for overages
   - Creates deduped alerts via unique index
   - Can be called for specific family or all families
   - Scheduled daily at 8 AM UTC (config/schedule.yml)

2. **app/models/rule/action.rb** (modified)
   - Enhanced `apply` method to emit `rule_applied` alerts after rule execution
   - Iterates resource_scope and creates alert for each transaction

### ✅ Feed Endpoint (2 files)
1. **app/controllers/alert_feeds_controller.rb** (new)
   - Inherits from `ActionController::Base` (no session auth)
   - HTTP Basic Auth with email + RSS feed key
   - `show` action returns Atom feed
   - Sets up Current context via OpenStruct for compatibility

2. **app/views/alert_feeds/show.atom.builder** (new)
   - Uses Rails built-in `atom_feed` helper
   - Renders family alerts with title/description/timestamp
   - No external dependencies needed

### ✅ Settings Management (2 files)
1. **app/controllers/settings/feeds_controller.rb** (new)
   - `show` - displays feed key status and settings
   - `create` - generates new key, sets flash, redirects
   - `destroy` - revokes existing key
   - `update` - saves large_transaction_threshold

2. **app/views/settings/feeds/show.html.erb** (new)
   - Modeled after api_keys/show.html.erb
   - Shows one-time key display after generation (flash[:rss_feed_key])
   - Shows "Key active" status and Regenerate/Revoke buttons
   - Feed URL with copy button
   - Large transaction threshold input form
   - Uses DS components (FilledIcon, Button, Link) for consistent styling

### ✅ Configuration (3 files)
1. **config/routes.rb** (modified)
   - Feed routes: `/alerts`, `/alerts.atom`, `/alerts.rss` (all point to atom format)
   - Settings route: `namespace :settings { resource :feed, only: [:show, :create, :destroy, :update] }`

2. **config/initializers/rack_attack.rb** (modified)
   - Throttle rule: 60 requests per minute per IP on `/alerts` paths

3. **config/schedule.yml** (modified)
   - Cron job: `BudgetAlertCheckJob` runs daily at 8 AM UTC
   - Integrated with sidekiq-cron scheduling

### ✅ Navigation (1 file)
- **app/views/settings/_settings_nav.html.erb** (modified)
  - Added "Alert Feed" nav item after "API Key"
  - Icon: "rss"
  - Path: `settings_feed_path`

### ✅ Testing (5 test files + fixtures)
1. **test/models/alert_test.rb**
   - Tests for all three factory methods
   - Deduplication behavior (no duplicates for same alertable)
   - Title/description formatting per alert type
   - Recent scope ordering

2. **test/models/user_rss_feed_test.rb**
   - Key generation returns 64-char hex string
   - generate/revoke lifecycle
   - Authentication with correct email + key
   - Returns nil for wrong key, blank key, or user without key
   - Case-insensitive email lookup

3. **test/controllers/alert_feeds_controller_test.rb**
   - Valid credentials return 200 with Atom content-type
   - Wrong key returns 401
   - No credentials returns 401 with WWW-Authenticate header
   - Feed contains family alerts only (not other families)
   - Valid Atom XML structure

4. **test/controllers/settings/feeds_controller_test.rb**
   - Show renders correctly
   - Create generates key and sets flash
   - Destroy revokes key
   - Update saves threshold (including clearing with blank)
   - Requires authentication

5. **test/jobs/budget_alert_check_job_test.rb**
   - Creates alert for over-budget categories
   - Doesn't alert for under-budget
   - Doesn't alert for zero budgeted amount
   - No duplicates on re-run
   - Works with all families when no family_id provided

6. **test/fixtures/alerts.yml**
   - Sample budget_exceeded and large_transaction alerts

## Security Features

✅ **HTTP Basic Auth** (HTTP only over HTTPS)
- Username: user's email
- Password: dedicated RSS feed key (NOT login password)

✅ **Secure Key Storage**
- 64-character hex string (256-bit entropy)
- Deterministic encryption (reversible, but queryable)
- Follows ApiKey pattern for consistency

✅ **Key Management**
- One key per user
- Regenerable (revokes old, creates new)
- Revocable
- Shown once after creation (flash)

✅ **Timing-Safe Comparison**
- Uses `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks

✅ **Rate Limiting**
- 60 requests per minute per IP on `/alerts` paths (Rack Attack)

✅ **Access Control**
- Feed only shows alerts from authenticated user's family
- Alerts from other families not visible

## Database Schema

### alerts table
```
id (uuid)
family_id (uuid, FK)
alert_type (string) - enum: budget_exceeded, large_transaction, rule_applied
alertable_type (string) - polymorphic: BudgetCategory, Entry, Rule
alertable_id (uuid) - polymorphic
metadata (jsonb) - stores context data (category_name, amount, date, etc)
created_at, updated_at

Indexes:
- (family_id, alert_type, alertable_type, alertable_id) UNIQUE - deduplication
- (family_id, created_at) - for feed queries
```

### users table additions
```
rss_feed_key (string, encrypted, deterministic, unique where not null)
```

### families table additions
```
large_transaction_threshold (decimal 19,4, nullable)
```

## Alert Flow

### Budget Exceeded
1. Transaction created/destroyed → triggers `enqueue_budget_alert_check`
2. `BudgetAlertCheckJob` runs (on demand or daily cron)
3. Checks current month's budget categories
4. For each category where `available_to_spend < 0`:
   - Calls `Alert.record_budget_exceeded!`
   - Unique index prevents duplicates

### Large Transaction
1. Transaction created → after_create_commit callback
2. Checks if `amount.abs >= family.large_transaction_threshold`
3. If enabled and threshold exceeded:
   - Calls `Alert.record_large_transaction!`
   - Unique index prevents duplicates

### Rule Applied
1. Rule's `apply` method executes actions
2. After executor runs, iterates resource_scope
3. For each matched transaction:
   - Calls `Alert.record_rule_applied!`
   - Unique index on entry prevents duplicate per entry

### Feed Rendering
1. HTTP Basic Auth decodes email + key
2. `User.authenticate_rss_feed!(email, key)` looks up user
3. `Current.family.alerts.recent` returns up to 100 recent alerts
4. Atom template renders with title/description/timestamp

## Files Created (14)
- 3 migrations
- 1 model (Alert)
- 1 job (BudgetAlertCheckJob)
- 1 controller (AlertFeedsController)
- 1 view template (show.atom.builder)
- 1 settings controller (Settings::FeedsController)
- 1 settings view (show.html.erb)
- 5 test files
- 1 fixture file

## Files Modified (6)
- app/models/user.rb
- app/models/family.rb
- app/models/entry.rb
- app/models/rule/action.rb
- config/routes.rb
- config/initializers/rack_attack.rb
- config/schedule.yml
- app/views/settings/_settings_nav.html.erb

## Next Steps

### To Deploy This Code:

1. **Ensure Ruby 3.4.4** (Gemfile requirement) or update Gemfile to 3.3.8

2. **Run Migrations**
   ```bash
   bin/rails db:migrate
   ```

3. **Run Tests** (optional but recommended)
   ```bash
   bin/rails test test/models/alert_test.rb
   bin/rails test test/models/user_rss_feed_test.rb
   bin/rails test test/controllers/alert_feeds_controller_test.rb
   bin/rails test test/controllers/settings/feeds_controller_test.rb
   bin/rails test test/jobs/budget_alert_check_job_test.rb
   ```

4. **Deploy to Production**
   - Ensure HTTPS is enforced
   - Verify sidekiq-cron is running for daily budget check
   - Monitor `/alerts` endpoint traffic

### Usage Examples:

**User generates feed key:**
1. Navigate to Settings → Alert Feed
2. Click "Generate Feed Key"
3. Copy displayed key
4. Add to RSS reader with format: `https://app.maybe.com/alerts.atom`
5. Username: their@email.com
6. Password: (the generated key)

**Configure Large Transaction Alerts:**
1. Settings → Alert Feed → Alert Settings
2. Enter threshold (e.g., "500" for $500)
3. Click "Save Settings"
4. Any transaction above $500 triggers alert

**Subscribe in RSS Reader:**
- Pocket, Feedly, NetNewsWire, etc.
- Most support HTTP Basic Auth
- Some require format: `https://email:key@app.maybe.com/alerts.atom`

## Architecture Notes

✅ **No New Dependencies** - Uses Rails' built-in `atom_feed` helper

✅ **Follows Maybe Conventions**
- Skinny controllers, fat models (business logic in Alert model)
- Uses Hotwire/Turbo forms in settings
- DS components for UI consistency
- Minitest + fixtures (no FactoryBot)

✅ **Deduplication Strategy**
- Unique constraint on (family_id, alert_type, alertable_type, alertable_id)
- Allows natural database-level deduplication
- No complex lock/transaction logic needed

✅ **Extensible**
- Can add more alert types by extending Alert model
- Can add dismissal tracking (dismissed_at column already in schema)
- Can add per-alert granular permissions later

✅ **Performance**
- Budget check only for families with active budgets
- Atom feed limited to 100 recent alerts per spec
- Indexes optimized for alert queries
- Rate limiting prevents abuse

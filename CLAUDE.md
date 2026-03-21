# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Setup
bin/setup                    # Install gems, prepare DB, clear logs/tmp

# Development
bin/rails server             # Start server on http://localhost:3000
bin/rails db:migrate         # Run pending migrations

# Testing
bin/rails test               # Run unit tests
bin/rails test:system        # Run system tests (Capybara + Selenium)
bin/rails test path/to/test  # Run a single test file

# Linting
bundle exec rubocop          # Ruby linter (120 char max line length)
bundle exec rubocop -a       # Auto-fix offenses

# Assets
bin/rails assets:precompile  # Precompile for production
```

## Architecture

**MTracker** is a Rails 7.1 personal finance tracker (expenses, incomes, investments). Classic MVC with Hotwire (Turbo + Stimulus) — no Node.js/webpack; JavaScript is managed via importmap.

### Core Models

- `User` — Devise-managed authentication; has many expenses, incomes, investments, chats
- `Expense` — has `expense_type` (category), `value`, `date`, `description`
- `Income` — has `income_type` (category), `value`, `date`, `description`
- `Investment` — has `investment_type`, `value`, `date`, `description`, `interest_rate`; computes `current_value` (compound interest) and `accumulated_yield`
- `Chat` / `Message` — AI chat with financial context; messages have `role` (user/assistant) and `content`

### Key Controllers

- `PagesController` — home (public) and dashboard (authenticated); dashboard has month/year filter logic and aggregates financial summaries
- `ExpensesController`, `IncomesController`, `InvestmentsController` — standard CRUD, all scoped to `current_user`
- `InvestmentsController#returns` — collection action showing investment returns/yields
- `StreamsController` — SSE endpoint for streaming AI chat responses; uses `RubyLLM` with `gpt-4o`; detects transaction descriptions in responses and auto-creates records via a `[TRANSACTION:{...}]` JSON marker
- `SettingsController` — theme, password, email update
- `ApplicationController` — enforces `authenticate_user!` globally

### Frontend Stack

- **Bootstrap 5.3** via gem + **SCSS** with component-level stylesheets under `app/assets/stylesheets/components/`
- **Stimulus controllers** in `app/javascript/controllers/` handle: theme toggle (dark/light stored in localStorage), sidebar toggle, Chart.js expense/investment category charts
- **Chart.js 4.4.1** imported via importmap for financial visualizations
- Theme applied via `data-theme` attribute on `<html>`; CSS variables defined in `app/assets/stylesheets/config/_theme.scss`

### Layouts

Three layouts: `application` (auth pages), `dashboard` (main app), `settings` (settings panel). Dashboard layout includes the sidebar partial.

### Routes

```
root → pages#home
dashboard → pages#index (filtered by params[:month], params[:year])
resources :expenses, :incomes
resources :investments do; get :returns, on: :collection; end
resources :chats, only: [:index, :show, :create, :destroy] do
  resources :messages, only: [:create]
end
/settings/* → SettingsController actions (index, theme, password, email, support)
streams/:chat_id → StreamsController#show (SSE)
devise_for :users
```

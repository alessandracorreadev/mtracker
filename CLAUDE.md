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
- `Expense` — has `expense_type` (category), amount, date, description
- `Income` — similar structure to Expense
- `Investment` — has `investment_type` (category), amount, date, description
- `Chat` / `Message` — nested resources, experimental feature

### Key Controllers

- `PagesController` — home (public) and dashboard (authenticated); dashboard has month/year filter logic and aggregates financial summaries
- `ExpensesController`, `IncomesController`, `InvestmentsController` — standard CRUD, all scoped to `current_user`
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
resources :expenses, :incomes, :investments
resources :chats do; resources :messages; end
/settings/* → SettingsController actions
devise_for :users
```

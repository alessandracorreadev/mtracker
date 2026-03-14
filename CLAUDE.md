# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Setup
bundle install
bin/rails db:create db:migrate db:seed

# Development server
bin/rails server

# Tests
bin/rails test                          # All tests
bin/rails test test/models/user_test.rb # Single test file

# Linting (RuboCop, excludes bin/, db/, config/, test/)
bundle exec rubocop
bundle exec rubocop -a  # Auto-correct
```

## Architecture

**MTracker** is a Rails 7.1 personal finance tracker with expense, income, and investment management plus a chat feature.

### Authentication & Authorization
- Devise handles all auth; `ApplicationController` enforces `authenticate_user!` globally
- `PagesController#home` is the only public action (skips authentication)
- All resource queries are scoped to `current_user` (e.g., `current_user.expenses`)
- Devise permits `:name` and `:birth_date` as extra sign-up parameters

### Data Model
- **User** → has_many: expenses, incomes, investments, chats (all `dependent: :destroy`)
- **Expense / Income / Investment** — each has: `date`, `value` (decimal), `*_type` (string), `description`, `user_id`
- **Chat** → has_many :messages; **Message** has `content`, `role`, `chat_id`

### Controllers
- `ExpensesController`, `IncomesController`, `InvestmentsController` — full CRUD, user-scoped
- `ChatsController` — index, show, create, destroy only
- `MessagesController#create` — stub (currently incomplete)
- `PagesController` — `home` (public landing), `index` (authenticated dashboard that loads all three resource collections)

### Routes
```ruby
devise_for :users
root to: "pages#home"
get "dashboard" => "pages#index"
resources :expenses
resources :incomes
resources :investments
resources :chats, only: [:index, :show, :create, :destroy] do
  resources :messages, only: [:create]
end
```

### Stack
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5.3, Font Awesome
- **Forms**: Simple Form
- **Database**: PostgreSQL
- **Ruby**: 3.3.5

### RuboCop
Max line length is 120. Many cops are disabled — check `.rubocop.yml` before enabling new cops.

# Wallet Currency API

A Rails API application for managing multi-currency wallets with currency conversion capabilities.

## Features

- **Multi-currency wallet management**: Support for USD and MXN currencies
- **Wallet funding**: Add money to wallets in different currencies
- **Currency conversion**: Convert between USD and MXN using hardcoded exchange rates
- **Withdrawal**: Remove money from wallets with insufficient funds protection
- **Balance inquiry**: Check current balances across all currencies

## Ruby version

- Ruby 3.x (check `.ruby-version` for specific version)
- Rails 8.0

## System dependencies

- SQLite3 (for development and test databases)
- Bundler gem management

## Database setup

```bash
# Create and migrate the database
rails db:create
rails db:migrate

# For test environment
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

## Configuration

The application uses hardcoded exchange rates:
- USD to MXN: 18.70
- MXN to USD: 0.053

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd wallet-currency

# Install dependencies
bundle install

# Setup database
rails db:setup
```

## API Endpoints

### Fund Wallet
```
POST /wallets/:user_id/fund
Parameters: { amount: Number, currency: String }
```

### Convert Currency
```
POST /wallets/:user_id/convert
Parameters: { from_currency: String, to_currency: String, amount: Number }
```

### Withdraw from Wallet
```
POST /wallets/:user_id/withdraw
Parameters: { currency: String, amount: Number }
```

### Get Balances
```
GET /wallets/:user_id/balances
Returns: { "USD": "100.0", "MXN": "1870.0" }
```

## How to run the test suite

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/wallet_spec.rb
bundle exec rspec spec/requests/wallets_spec.rb

# Run with coverage (if configured)
bundle exec rspec --format documentation
```

## Models

- **User**: Basic user model with name attribute
- **Wallet**: Belongs to user, contains currency and balance with validations:
  - Currency presence validation
  - Balance numericality validation (no negative values)
  - User association validation

## Development

This application runs in a dev container with:
- Debian GNU/Linux 12 (bookworm)
- Pre-installed tools: Git, Docker CLI, GitHub CLI
- All necessary Ruby/Rails development dependencies

### Running the server

```bash
rails server
```

### Database console

```bash
rails console
```

## Testing

The application uses RSpec for testing with:
- Model tests with Shoulda Matchers
- Request tests for API endpoints
- Factory patterns for test data creation

## Deployment

This is a development application. For production deployment, consider:
- Environment-specific database configuration
- External exchange rate API integration
- Authentication and authorization
- Rate limiting and security

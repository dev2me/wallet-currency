# Wallet Currency API

A Rails API application for managing multi-currency wallets with currency conversion capabilities and comprehensive error handling.

## Features

- **Multi-currency wallet management**: Support for USD and MXN currencies
- **Wallet funding**: Add money to wallets in different currencies
- **Currency conversion**: Convert between USD and MXN using hardcoded exchange rates
- **Withdrawal**: Remove money from wallets with insufficient funds protection
- **Balance inquiry**: Check current balances across all currencies
- **Transaction history**: Track all wallet operations with detailed records
- **Reconciliation**: Verify wallet balances against transaction history
- **Comprehensive error handling**: Structured error responses with error codes

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

The application uses hardcoded exchange rates via FxService:
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
Response: Wallet object with updated balance
```

### Convert Currency
```
POST /wallets/:user_id/convert
Parameters: { from_currency: String, to_currency: String, amount: Number }
Response: { from: Wallet, to: Wallet }
```

### Withdraw from Wallet
```
POST /wallets/:user_id/withdraw
Parameters: { currency: String, amount: Number }
Response: Wallet object with updated balance
```

### Get Balances
```
GET /wallets/:user_id/balances
Response: { "USD": "100.0", "MXN": "1870.0" }
```

### Get Transaction History
```
GET /wallets/:user_id/transactions
Response: Array of transaction objects ordered by created_at desc
```

### Reconciliation Check
```
GET /wallets/:user_id/reconciliation
Response: {
  "net_funding_minus_withdrawals": 1000.0,
  "current_balance": 1000.0,
  "ok": true
}
```

## Error Handling

The API provides structured error responses with error codes:

- `USER_NOT_FOUND` (404): User does not exist
- `INSUFFICIENT_FUNDS` (422): Not enough balance for operation
- `SAME_CURRENCY_CONVERSION` (400): Cannot convert same currency
- `BAD_REQUEST` (400): Invalid parameters (amount, currency)
- `INTERNAL_ERROR` (500): Unexpected server error

Example error response:
```json
{
  "error": "Insufficient funds in USD wallet",
  "error_code": "INSUFFICIENT_FUNDS",
  "currency": "USD"
}
```

## Testing with curl

```bash
# Start the server
rails server

# Create a user first in rails console
rails console
> user = User.create!(name: "Test User")
> user.id

# Fund a wallet
curl -X POST http://localhost:3000/wallets/1/fund \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "currency": "USD"}'

# Convert currency
curl -X POST http://localhost:3000/wallets/1/convert \
  -H "Content-Type: application/json" \
  -d '{"from_currency": "USD", "to_currency": "MXN", "amount": 100}'

# Check balances
curl http://localhost:3000/wallets/1/balances

# View transactions
curl http://localhost:3000/wallets/1/transactions
```

## How to run the test suite

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/wallet_spec.rb
bundle exec rspec spec/requests/wallets_spec.rb

# Run with detailed output
bundle exec rspec --format documentation

# Check test coverage
bundle exec rspec --format progress
```

## Models

### User
- Basic user model with name attribute
- Has many wallets and wallet_transactions

### Wallet
- Belongs to user
- Contains currency and balance with validations:
  - Currency presence validation
  - Balance numericality validation (no negative values)
  - User association validation
- Class method `for(user, currency)` to find or initialize wallet

### WalletTransaction (Transaction)
- Belongs to user
- Enum transaction_type: `{ fund: 0, convert: 1, withdraw: 2 }`
- Tracks all wallet operations with amounts and currencies

## Services

### FxService
- Handles currency conversion with hardcoded rates
- Methods: `convert(from, to, amount)` and `rate_for(from, to)`
- Validates currencies and amounts

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

### Available development tools

```bash
# Check routes
rails routes

# Open Rails console
rails console

# Run migrations
rails db:migrate

# Reset database
rails db:reset

# Check application status
rails about
```

## Testing

The application uses RSpec for testing with:
- Model tests with Shoulda Matchers for associations and validations
- Request tests for API endpoints with proper error handling
- Service tests for FxService functionality
- Comprehensive test coverage for edge cases

## Deployment

This is a development application. For production deployment, consider:
- Environment-specific database configuration (PostgreSQL recommended)
- External exchange rate API integration (replacing hardcoded rates)
- Authentication and authorization (JWT tokens, API keys)
- Rate limiting and security measures
- Logging and monitoring setup
- Docker containerization for consistent deployment
- Database connection pooling and optimization
- Error tracking (Sentry, Rollbar)
- Performance monitoring (New Relic, DataDog)

## Architecture Notes

- **Error handling**: Centralized rescue handlers in ApplicationController
- **Validation**: Input validation with detailed error messages
- **Transactions**: Database transactions ensure data consistency
- **Service layer**: FxService isolates exchange rate logic
- **Model layer**: Wallet.for method encapsulates wallet creation logic
- **Testing**: Comprehensive test suite with edge case coverage

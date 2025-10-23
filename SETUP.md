# SafePay Ghana - Local Development Setup Guide

## Prerequisites

- **Node.js** v16+ and npm
- **PostgreSQL** v12+
- **Flutter** v3.0.0+
- **Git**

## Quick Start

### 1. Environment Configuration

#### Backend Setup
```bash
cd backend
cp .env.example .env
```

Edit `backend/.env` and configure:
- Database credentials (PostgreSQL)
- JWT secret (generate with: `openssl rand -base64 64`)
- Twilio credentials (for SMS OTP - optional for dev)

#### Mobile Setup
```bash
cd mobile
cp .env.example .env
```

Edit `mobile/.env`:
- Set `API_BASE_URL` based on your device:
  - **Android Emulator**: `http://10.0.2.2:3000/api`
  - **iOS Simulator**: `http://localhost:3000/api`
  - **Physical Device**: `http://YOUR_LOCAL_IP:3000/api` (e.g., `http://192.168.1.100:3000/api`)

### 2. Database Setup

```bash
# Create database
createdb safepay_ghana

# Run initial schema
psql -d safepay_ghana -f database/init.sql

# Run migrations
psql -d safepay_ghana -f database/migrations/001_update_users_table.sql
psql -d safepay_ghana -f database/migrations/002_create_escrow_tables.sql
```

### 3. Backend Setup

```bash
cd backend
npm install
npm start
```

The backend API will run on `http://localhost:3000`

### 4. Mobile App Setup

```bash
cd mobile
flutter pub get
flutter run
```

Choose your device/emulator when prompted.

## Testing the App

### 1. Register a User
- Open the app
- Enter phone number (e.g., +233123456789)
- Check backend console for OTP code
- Complete registration

### 2. Create a Test Transaction
1. Create 2 users (Buyer and Seller)
2. Note the Seller's User ID
3. Login as Buyer
4. Tap "New Purchase"
5. Enter Seller ID, amount, and details
6. Confirm transaction

### 3. Complete Transaction Flow
1. Login as Buyer
2. View transaction in "My Transactions"
3. Simulate delivery
4. Tap "Confirm Delivery" to release escrow

## Troubleshooting

### Backend won't start
- Check PostgreSQL is running: `pg_isready`
- Verify `.env` database credentials
- Check logs: Backend shows errors on startup

### Mobile app can't connect
- Verify backend is running: `curl http://localhost:3000/api/health`
- Check `API_BASE_URL` in `mobile/.env`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical device, ensure phone and laptop on same WiFi

### OTP not received
- Development mode: OTP printed in backend console
- Production: Configure Twilio credentials in `backend/.env`

### Database errors
- Ensure migrations ran: `psql -d safepay_ghana -c "\dt"`
- Check table existence: Should see `users`, `transactions`, `escrow_accounts`, etc.

## Development Tips

- **Backend logs**: Check console for API errors
- **Mobile logs**: `flutter logs` for detailed debugging
- **Database inspection**: Use `psql -d safepay_ghana` or pgAdmin
- **API testing**: Use Postman or curl

## Next Steps

- Configure Twilio for SMS OTP
- Add payment gateway (Paystack)
- Implement seller & rider interfaces
- Add dispute resolution

## Support

Check the main README.md for architecture details and feature documentation.

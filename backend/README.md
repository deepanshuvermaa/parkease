# ParkEase Backend API

Backend API for ParkEase Parking Management System built with Node.js, Express, and PostgreSQL.

## Features

- 🔐 JWT Authentication with refresh tokens
- 📱 Single device enforcement
- 🚗 Vehicle management with sync
- 👥 User and role management
- 🔄 Real-time updates via WebSocket
- 📊 Admin dashboard and reporting
- 🛡️ Rate limiting and security
- 📝 Audit logging

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT
- **Real-time**: Socket.io
- **Deployment**: Railway

## Installation

1. Clone the repository
```bash
git clone https://github.com/deepanshuvermaa/parkease.git
cd parkease/backend
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Set up database
```bash
# Create PostgreSQL database
createdb parkease

# Run migrations
psql -d parkease -f src/utils/schema.sql
```

5. Start the server
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/guest-signup` - Guest registration
- `GET /api/auth/sessions` - Get active sessions
- `DELETE /api/auth/sessions/:id` - Force logout device

### Vehicles
- `GET /api/vehicles` - Get vehicles list
- `POST /api/vehicles` - Add new vehicle
- `PUT /api/vehicles/:id` - Update vehicle (exit)
- `DELETE /api/vehicles/:id` - Delete vehicle
- `POST /api/vehicles/sync` - Bulk sync
- `GET /api/vehicles/active/count` - Active count

### Admin
- `GET /api/admin/dashboard` - Dashboard data
- `GET /api/admin/stats` - Statistics
- `GET /api/admin/users` - User management
- `GET /api/admin/devices` - Device management
- `POST /api/admin/force-logout` - Force logout
- `GET /api/admin/reports` - Generate reports

### Users
- `GET /api/users/profile` - Get profile
- `PUT /api/users/profile` - Update profile
- `PUT /api/users/password` - Change password
- `GET /api/users/subscription` - Subscription info

### Settings
- `GET /api/settings` - Get settings
- `PUT /api/settings` - Update settings

## WebSocket Events

### Client to Server
- `authenticate_device` - Device authentication
- `vehicle_update` - Vehicle data update
- `request_stats` - Request statistics (admin)
- `admin_force_logout` - Force logout user (admin)

### Server to Client
- `authenticated` - Authentication success
- `sync_vehicle` - Vehicle sync data
- `stats_update` - Statistics update
- `force_logout` - Force logout event
- `dashboard_update` - Dashboard update

## Deployment

### Railway Deployment

1. Create new project on Railway
2. Add PostgreSQL database
3. Connect GitHub repository
4. Set environment variables:
   - `DATABASE_URL` (auto-configured)
   - `JWT_SECRET`
   - `JWT_REFRESH_SECRET`
   - `ADMIN_PANEL_URL`

5. Deploy from GitHub

### Environment Variables

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://...
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
ADMIN_PANEL_URL=https://your-admin-panel.com
```

## Security

- CORS configured for specific origins
- Helmet.js for security headers
- Rate limiting on API endpoints
- SQL injection prevention
- XSS protection
- JWT token expiry
- Password hashing with bcrypt

## License

MIT

## Support

For support, email support@go2billingsoftwares.com

---

**Powered by Go2 Billing Softwares**
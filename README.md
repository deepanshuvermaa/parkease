# ParkEase - Smart Parking Management System

A comprehensive parking management solution with Flutter mobile app and Node.js backend.

## 🚀 Features

### Mobile App (Flutter)
- ✅ Vehicle entry/exit management
- ✅ Customizable ticket ID generation
- ✅ Bluetooth thermal printer support
- ✅ Advanced print customization
- ✅ Flexible parking charges configuration
- ✅ QR code generation on receipts
- ✅ Offline-first architecture
- ✅ Real-time data synchronization
- ✅ Multi-device support with single login
- ✅ Guest mode with 3-day trial
- ✅ Reports and analytics

### Backend (Node.js)
- 🔐 JWT authentication with refresh tokens
- 📱 Single device enforcement
- 🔄 Real-time updates via WebSocket
- 📊 Admin dashboard
- 🛡️ Role-based access control
- 📝 Audit logging
- 🚦 Rate limiting
- 🗄️ PostgreSQL database

### Admin Panel
- 📊 Real-time statistics
- 👥 User management
- 📱 Device control
- 📈 Reports generation
- ⚙️ System settings

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Database**: SQLite (local)
- **Printing**: Bluetooth Serial & ESC/POS

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Real-time**: Socket.io
- **Deployment**: Railway

## 📱 Mobile App Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio / VS Code
- Android device/emulator

### Installation

```bash
# Clone repository
git clone https://github.com/deepanshuvermaa/parkease.git
cd parkease

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Build APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## 🖥️ Backend Setup

### Prerequisites
- Node.js 18+
- PostgreSQL
- Railway account (for deployment)

### Installation

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Setup database
psql -d parkease -f src/utils/schema.sql

# Seed initial data
npm run seed

# Start server
npm start
```

## 🚀 Deployment

### Backend Deployment (Railway)

1. Push code to GitHub
2. Create new Railway project
3. Add PostgreSQL database
4. Connect GitHub repository
5. Set environment variables
6. Deploy

### Admin Panel

The admin panel is available at: https://deepanshuvermaa.github.io/quickbill-admin

## 📝 Default Credentials

### Mobile App
- **Demo User**: demo / demo123
- **Admin**: admin / admin123

### Features by Version

#### v1.2.1 (Latest)
- **Receipt Customization**: Complete receipt settings screen with 3-tab interface
- **Logo Upload**: Company logo support for receipt headers with image picker
- **Ticket ID Enhancement**: 4 industry-standard patterns + custom pattern support
- **Font Size Control**: Individual font size settings for all receipt elements
- **Prominent Ticket ID**: Larger, bold ticket ID display in receipts
- **Mandatory Branding**: Non-removable "Powered by Go2 Billing Softwares" footer
- **UI Improvements**: Fixed overflow issues across all screens for better responsiveness
- **App Icon Update**: Replaced Flutter logo with Go2 Billing Software logo
- **Entry Dialog Optimization**: Removed Done button, kept only Print Ticket button
- **Base64 Image Handling**: Efficient logo storage and ESC/POS image processing
- **Railway Deployment**: Full cloud deployment setup with PostgreSQL integration

#### v1.2.0
- Customizable ticket ID patterns
- Advanced print customization
- QR code on receipts
- Improved UI/UX

#### v1.1.0
- Flexible parking charges
- Grace period support
- Vehicle-specific rates
- Bluetooth printer fixes

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open pull request

## 📄 License

MIT License

## 🆘 Support

For support, email: support@go2billingsoftwares.com

## 👨‍💻 Developer

**Deepanshu Verma**
- GitHub: [@deepanshuvermaa](https://github.com/deepanshuvermaa)

---

**Powered by Go2 Billing Softwares**

© 2025 ParkEase. All rights reserved.

# MachK3y - End-to-End Encrypted Password Manager

A secure, zero-knowledge password manager built with Flutter and Supabase, featuring end-to-end encryption and a beautiful cartoon-style UI.

## 🔐 Security Features

- **Zero-Knowledge Architecture**: All data is encrypted on-device before being sent to the server
- **End-to-End Encryption**: AES-256-GCM encryption with PBKDF2 key derivation (100k iterations)
- **Master Password Protection**: Separate master password for vault encryption
- **Recovery Key System**: 24-word mnemonic recovery key for account recovery
- **Biometric Unlock**: Fingerprint/Face ID support for quick vault access
- **Auto-lock**: Automatic vault locking after inactivity
- **Have I Been Pwned Integration**: Check for compromised passwords

## ✨ Features

### Core Functionality
- **Secure Vault**: Store passwords, credit cards, and other sensitive data
- **Password Generator**: Create strong passwords with customizable options
- **Security Audit**: Identify weak, reused, and compromised passwords
- **Password Strength Analysis**: Real-time password strength evaluation
- **Credential Sharing**: Securely share credentials with other users
- **Multi-platform Support**: iOS, Android, Web, Desktop

### Credential Types
- **Email Accounts**: Work and personal email credentials
- **Website Logins**: Social media, e-commerce, and service accounts
- **Credit Cards**: Card details with secure storage
- **Social Media**: Platform-specific credentials
- **Custom Fields**: Flexible storage for any type of credential

### User Experience
- **Cartoon-style Design**: Friendly, approachable interface
- **Dark/Light Themes**: Automatic theme switching
- **Responsive Design**: Optimized for all screen sizes
- **Smooth Animations**: Delightful micro-interactions
- **Intuitive Navigation**: Easy-to-use interface
- **Onboarding Tutorial**: Guided setup for new users

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Supabase account
- iOS/Android development environment (for mobile)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/machk3y.git
   cd machk3y
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a new Supabase project
   - Run the SQL schema from `supabase_schema.sql`
   - Get your project URL and anon key

4. **Configure environment**
   - Update `lib/core/services/supabase_service.dart` with your Supabase credentials

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Development

### Project Structure
```
lib/
├── core/
│   ├── constants/          # App constants and configuration
│   ├── theme/             # Theme and styling
│   ├── utils/             # Utility functions
│   └── services/          # Core services (encryption, auth, etc.)
├── models/                # Data models
├── providers/             # State management
├── screens/               # UI screens
└── widgets/               # Reusable UI components
```

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

### FAQ

**Q: What if I forget my master password?**
A: Use your recovery key to reset your master password. Without the recovery key, your data cannot be recovered.

**Q: Is my data safe?**
A: Yes, all data is encrypted with industry-standard encryption before being stored. We never see your plaintext data.

**Q: Can I use this offline?**
A: Yes, the app works offline. Data syncs when you're back online.

---

**Made with ❤️ for security-conscious users**
**🚀 FlowLink Mobile App**

AI-Powered Conversational Payment & Service Platform
Seamlessly connect, chat, and transact — all within one smart interface.

**🧠 Overview**

FlowLink is a next-gen AI-integrated mobile application that merges real-time chat assistance, intelligent automation, and secure payment processing to deliver an unparalleled mobile experience.

Built with Flutter, powered by GPT-based AI, and secured with Razorpay, FlowLink dynamically adapts to user needs — enabling a seamless fusion of conversation, context, and commerce.

**✨ Key Features**
💬 Smart Conversational Assistant

Powered by OpenAI GPT API

Context-aware chat responses

Voice-to-text integration for hands-free experience

Dynamic action commands via chat (e.g., “Send payment”, “Book service”)

**💳 Integrated Payments**

Real-time Razorpay integration for instant UPI & card transactions

Test & live modes supported

Transaction history and smart payment suggestions

**🔐 Secure & Scalable Backend**

Built with Node.js + Express and hosted on Render / Vercel

MongoDB Atlas for secure cloud database

JWT-based authentication for user security

**🧩 Dynamic Configurations**

Environment-based API control using Dart defines

Supports multiple backends for staging & production

Real-time assistant model switching (gpt-4o, gpt-4o-mini, etc.)

**🪄 Modern UI/UX**

Flutter 3.x with Material 3 design principles

Adaptive themes (Light/Dark)

Smooth animations & responsive layouts

Optimized for Android & iOS

**🏗️ Tech Stack**
Layer	Technology	Purpose
Frontend	Flutter	Cross-platform mobile app
Backend	Node.js, Express	API, authentication, AI orchestration
Database	MongoDB Atlas	Cloud-based document storage
AI Model	GPT-4o / GPT-4o-mini	Conversational AI
Payment	Razorpay	Secure online payments
Hosting	Render / Vercel	Cloud deployment
Auth	JWT	Secure token-based access
**⚙️ Environment Setup
🧩 Flutter Build Configuration**
flutter build apk --release \
  --dart-define=ASSISTANT_API_URL=https://flowlink-mobile.onrender.com/assistant \
  --dart-define=ASSISTANT_MODEL=openai/gpt-4o-mini \
  --dart-define=RAZORPAY_KEY=rzp_test_RQy2o2G1jHYSMe

**📁 Required .env (Backend)**
MONGODB_URI=your_mongodb_atlas_connection_string
JWT_SECRET=your_jwt_secret
CLIENT_ORIGIN=https://flowlink-mobile.vercel.app
FRONTEND_URL=https://flowlink-mobile.vercel.app
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_SECRET=your_razorpay_secret

**🧠 Assistant Architecture**
User Query
   ↓
FlowLink Assistant (Flutter)
   ↓
Express API (Node.js)
   ↓
GPT Model via OpenAI API
   ↓
Response + Action


**✅ Supports Context Memory, Action Intents, and Payment Triggers.**
Example:

User: "Pay ₹500 to Rahul"
Assistant: "Confirming payment of ₹500 via Razorpay…"

**🧪 Testing Razorpay in Development**

Enable test mode in Flutter by using your test key:

const razorpayKey = String.fromEnvironment('RAZORPAY_KEY', defaultValue: 'rzp_test_12345');


Then simulate transactions using Razorpay’s sandbox environment.

**📦 Folder Structure**
flowlink_mobile/
│
├── lib/
│   ├── main.dart
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   │   ├── assistant_service.dart
│   │   └── razorpay_service.dart
│   └── config/
│
├── assets/
│   ├── icons/
│   ├── images/
│   └── fonts/
│
├── pubspec.yaml
└── README.md

**🔥 Highlights of Uniqueness**

AI-Driven UI: Interface changes dynamically based on chat context.

Conversation-to-Action Flow: Convert text into executable payment or service operations.

Offline-Aware Assistant: Caches queries and syncs when online.

Multi-Model Support: Seamlessly swap between AI models without code changes.

Future-Ready: Designed to plug in new APIs (e.g., Stripe, Gemini, or Firebase) easily.

**📲 Installation & Run**
1️⃣ Clone the Repository
git clone https://github.com/yourusername/FlowLink-Mobile.git
cd FlowLink-Mobile

**2️⃣ Install Dependencies**
flutter pub get

**3️⃣ Run in Debug Mode**
flutter run

**🧬 Future Roadmap**

 AI-based transaction analytics

 Push notification with smart alerts

 User wallet & loyalty system

 Multi-language support

 Integration with Google Pay / Paytm

**🧑‍💻 Contributors**
Name	Role	Contact
Sujal Khedekar	Lead Developer / Designer	GitHub
 · LinkedIn
📜 License

This project is licensed under the MIT License — free for personal and commercial use with attribution.

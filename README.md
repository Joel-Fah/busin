![BusIn Presentation](assets/images/presentation.png)

# 🚌 BusIn - The Campus Bus Revolution

### *Because managing student transportation shouldn't feel like herding cats*

[![Flutter Version](https://img.shields.io/badge/Flutter-3.35.6-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## The Story

Picture this: It's 7 AM on a Monday morning. Students are rushing to catch the campus bus. Some have
subscriptions, some don't. Some are verified, others are... let's just say "creatively attempting"
to board. The admin is juggling a clipboard, a pen that keeps running out of ink, and a growing line
of impatient students. Chaos? Absolutely. Fun? Not really.

**Enter BusIn**

We looked at this mess and thought, *"There's got to be a better way."* So we built one. Not with
duct tape and prayers (though we considered it), but with Flutter, Firebase, and a healthy dose of
caffeine.

BusIn is not just an app; it's a **digital revolution** for campus bus management. Think of it as
the superhero your transportation system didn't know it needed—cape optional, efficiency guaranteed.

---

## 🎯 The Problem (aka The Chaos We're Solving)

Let's be real. Managing student bus subscriptions the old-fashioned way is like trying to solve a
Rubik's cube... blindfolded... while riding a unicycle. Here's what we were dealing with:

- 📝 **Paper-based madness**: Subscription forms getting lost faster than socks in a dryer
- 🕐 **Time-consuming verification**: Admins checking IDs manually like airport security
- 📊 **Zero analytics**: "How many students used the bus last semester?" *crickets*
- 🔐 **Security concerns**: Anyone could claim to be anyone (identity crisis, anyone?)
- 🌍 **Location tracking issues**: "Where did that student board?" "¯\\_(ツ)_/¯"
- 📱 **No real-time updates**: Students finding out their subscription expired... at the bus door

**The cherry on top?** Everything was disconnected, disorganized, and just plain **exhausting**.

---

## 💡 The Solution (Our Digital Magic Trick)

We built BusIn to turn that chaos into a well-oiled machine. Here's how we work our magic:

### For Students 👨‍🎓👩‍🎓

- **One-tap subscriptions**: Subscribe to semester bus service in seconds (yes, seconds!)
- **Personal QR codes**: Your ticket is literally *you* (well, your phone)
- **Real-time status**: Know exactly when your subscription is active, pending, or expired
- **Scan history**: See when and where you've been scanned (Big Brother, but make it useful)
- **Multi-language**: English & French support (Bonjour! 👋)

### For Admins & Staff 👔

- **Smart Dashboard**: Analytics that actually make sense (revolutionary, we know)
- **QR Scanner**: Scan student QRs faster than you can say "all aboard"
- **Approval System**: Review subscriptions with the swipe of a finger
- **People Management**: Track students, staff, and who's doing what
- **Semester Control**: Manage academic periods like a time wizard
- **Bus Stop Management**: Add, edit, or remove stops with Google Maps integration

### For Everyone 🌟

- **Dark Mode**: Because we care about your eyes (and aesthetic preferences)
- **Offline-capable**: Some features work even when the WiFi gods are angry
- **Secure**: Google Sign-In, role-based access, the whole security enchilada
- **Beautiful UI**: Material Design 3 meets custom flair

---

## 🎭 Target Audience

### Primary Users

- **Students** (the ones trying to get to class on time)
- **Bus Admins** (the unsung heroes managing the system)
- **Staff Members** (the verification squad)

### Secondary Users

- **University Administration** (for those sweet, sweet analytics)
- **Transportation Department** (data-driven decisions, anyone?)

### Who's NOT This For?

- People who enjoy chaos ❌
- Clipboard enthusiasts ❌
- Those allergic to efficiency ❌

---

## ✨ Features That'll Make You Go "Wow"

### 🎫 Subscription Management

- Create subscription requests with photo uploads
- Select preferred bus stops (with images & Google Maps!)
- Track subscription status in real-time
- Automatic semester-based validation
- Pull-to-refresh because we're fancy like that

### 📊 Analytics Dashboard (Admin Only)

- Real-time statistics (students, subscriptions, scans, staff)
- Beautiful charts (powered by fl_chart)
- Semester-wise breakdown
- Trending metrics
- Export-ready data

### 🔍 Smart Search & Filters

- Search by name, email, or student ID
- Filter subscriptions by status, semester, year
- Search people across roles
- Lightning-fast results (okay, maybe not lightning, but pretty darn fast)

### 👥 People Management

- View all students, staff, and admins
- Promote/demote staff members (with dramatic confirmation dialogs)
- Approve pending staff accounts
- Role-based badges (flex that admin status 💪)

### 🚏 Bus Stop Management

- Add stops with images and Google Maps locations
- Instagram-reel style card layout (because horizontal scrolling is cool)
- Edit/delete stops with confirmation
- Visual preview of locations

### 📅 Semester Management

- Define semester periods with exact dates
- Support for Fall, Spring, Summer
- Year-spanning semesters (Fall 2025 → Spring 2026)
- Choice chip selection (because dropdowns are so 2020)

### 📱 QR Code System

- Unique QR codes per student
- Fast scanning with mobile_scanner
- Location tracking (with privacy masks)
- Scan history with timestamps
- Screenshot protection (nice try, hackers 😏)

### 🔐 Security Features

- Google Sign-In (OAuth 2.0)
- Role-based access control (RBAC)
- Account verification system
- GPS masking for privacy (3.86***°N instead of exact coords)
- No screenshot on sensitive screens
- Session management

### 🎨 UX Delights

- Smooth animations (flutter_animate ftw)
- Custom themes (light/dark with seed colors)
- Haptic feedback
- Pull-to-refresh everywhere
- Loading states that don't make you want to throw your phone
- Error handling that's actually helpful

---

## 🚧 Challenges We Conquered (And Some Scars We Bear)

### Technical Challenges

#### 1. **The Semester Date Architecture** 📅

**The Problem**: How do you handle semesters that span multiple years (Fall 2025 starts in September
2025 but ends in February 2026)?

**The Solution**: We embedded the entire `SemesterConfig` object in subscriptions. One source of
truth, zero ambiguity.

**Lesson Learned**: When in doubt, embed the whole object. Denormalization > headaches.

---

#### 4. **The Firestore Index Hunt** 🔍

**The Problem**: Queries with `.where()` + `.orderBy()` need composite indexes. Forgot one? Enjoy
your crashes.

**The Solution**: Strategic query design + manual index creation + fallback to client-side sorting.

**Lesson Learned**: Firestore indexes are not optional. They're like vegetables—you need them even
if you don't want them.

---

#### 5. **The Image Upload Memory Crisis** 🖼️

**The Problem**: Uploading high-res images directly was eating RAM like Cookie Monster at a bakery.

**The Solution**: Supabase Storage + URL references in Firestore. Images live in S3, metadata lives
in Firestore.

**Lesson Learned**: Don't store large files in Firestore. Just don't. Your wallet will thank you.

---

### UX Challenges

#### 6. **The "Too Many Clicks" Problem** 🖱️

**The Problem**: Users needed 5 taps to do simple tasks. Ain't nobody got time for that.

**The Solution**:

- Long-press actions (promote staff)
- Swipe gestures
- Floating action buttons
- Bottom sheets instead of full pages

**Lesson Learned**: Every extra click is a user silently judging you.

---

#### 7. **The Dark Mode Dilemma** 🌓

**The Problem**: Colors that looked great in light mode were invisible in dark mode.

**The Solution**: Seed color palette system with theme-aware components. Every color adjusts
automatically.

**Lesson Learned**: Test in dark mode from day one, or suffer the consequences.

---

### Security Challenges

#### 8. **The Screenshot Scandal** 📸

**The Problem**: Students were screenshotting their QR codes and sharing them (creative, but no).

**The Solution**: `no_screenshot` package on the scannings tab + warning snackbars.

**Lesson Learned**: Users will find creative ways to break your security. Plan accordingly.

---

#### 9. **The Fake Admin Fiasco** 👑

**The Problem**: What if someone changes their role to "admin" in the Firestore console?

**The Solution**: Server-side validation + role verification on every sensitive operation.

**Lesson Learned**: Never trust the client. Ever. Not even a little bit.

---

## 🔒 Security Measures (We Take This Seriously)

### Authentication

- ✅ **Google OAuth 2.0**: No passwords to steal
- ✅ **Organization Email Verification**: Only @ictu-university.edu emails
- ✅ **Session Management**: Tokens, refresh, the whole shebang

### Authorization

- ✅ **Role-Based Access Control (RBAC)**: Student, Staff, Admin roles
- ✅ **Permission Checks**: Every action verifies user permissions
- ✅ **Account Status**: Verified, Pending, Suspended, Blocked states

### Data Protection

- ✅ **GPS Coordinate Masking**: `3.86***°N` instead of exact location
- ✅ **Screenshot Protection**: Disabled on sensitive screens
- ✅ **Firestore Security Rules**: For extra robustness from the backend service
- ✅ **HTTPS Everywhere**: All network calls encrypted

### Privacy

- ✅ **Minimal Data Collection**: Only what's needed
- ✅ **User Consent**: Permissions requested explicitly
- ✅ **Data Retention**: Old data gets cleaned up
- ✅ **Right to Delete**: Users can request account deletion

### Audit Trail

- ✅ **Scan Logging**: Who scanned whom, when, where
- ✅ **Modification Tracking**: `createdBy`, `updatedBy` fields
- ✅ **Timestamp Everything**: Know when stuff happened

---

## 🚀 Technical Stack

### Frontend

- **Flutter 3.9.2** - Because cross-platform is beautiful
- **Dart 3.9.2** - Null safety for the win
- **Material Design 3** - Google's design language
- **GetX 4.7.2** - State management without the boilerplate

### Backend & Database

- **Firebase Auth** - User authentication
- **Cloud Firestore** - NoSQL database (real-time awesomeness)
- **Supabase Storage** - S3-compatible file storage

### Key Packages (The Dream Team)

| Package                | Version | Purpose                 |
|------------------------|---------|-------------------------|
| `firebase_core`        | ^4.2.0  | Firebase initialization |
| `firebase_auth`        | ^6.1.1  | Authentication          |
| `cloud_firestore`      | ^6.0.3  | Database                |
| `supabase_flutter`     | ^2.10.3 | File storage            |
| `get`                  | ^4.7.2  | State management        |
| `go_router`            | ^17.0.1 | Navigation              |
| `mobile_scanner`       | ^7.1.3  | QR code scanning        |
| `qr_flutter`           | ^4.1.0  | QR code generation      |
| `fl_chart`             | ^1.1.1  | Beautiful charts        |
| `geolocator`           | ^14.0.1 | GPS location            |
| `flutter_animate`      | ^4.5.2  | Smooth animations       |
| `google_sign_in`       | ^7.2.0  | Google OAuth            |
| `hugeicons`            | ^1.1.1  | 10,000+ icons           |
| `cached_network_image` | ^3.4.1  | Image caching           |
| `timeago`              | ^3.7.1  | Relative timestamps     |
| `no_screenshot`        | ^0.3.1  | Screenshot protection   |

---

## 🛠️ Development Environment

### Prerequisites

```bash
# Flutter SDK
Flutter 3.35.6 • channel stable
Dart 3.9.2 • DevTools 2.48.0

# FVM (Flutter Version Management) - Recommended
fvm use 3.35.6

# IDE (Pick your poison)
- VS Code + Flutter extension
- Android Studio + Flutter plugin (recommended)
- IntelliJ IDEA + Flutter plugin
```

### Setup Instructions

#### 1. Clone the Repository

```bash
git clone https://github.com/your-org/busin.git
cd busin
```

#### 2. Install Dependencies

```bash
# Using FVM (recommended)
fvm flutter pub get

# Or regular Flutter
flutter pub get
```

#### 3. Environment Configuration

Create a `.env` file in the root directory:

```env
# Supabase
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key

# Other configs
ENVIRONMENT=development
```

#### 4. Firebase Setup

- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Place them in their respective directories
- Update `firebase_options.dart` with your config

#### 5. Run the App

```bash
# Development mode
fvm flutter run

# Production build
fvm flutter build apk --release  # Android
fvm flutter build appbundle --release  # PlayStore
fvm flutter build ios --release  # iOS
```

### Project Structure

```
lib/
├── api/                    # API clients
├── controllers/            # GetX controllers (state management)
├── models/                 # Data models
│   ├── actors/             # User models (Student, Staff, Admin)
│   └── value_objects/      # Semester, BusStop, etc.
├── services/               # Business logic & Firebase calls
├── ui/
│   ├── components/         # Reusable widgets
│   └── screens/            # App screens
├── utils/                  # Utilities & helpers
├── l10n/                   # Localization (EN/FR)
└── main.dart               # App entry point
```

---

## 🎨 Design Philosophy

We follow a few sacred principles:

### 1. **User First, Always**

If a feature confuses your grandma, it confuses everyone. Keep it simple.

### 2. **Performance is a Feature**

A beautiful app that stutters is like a sports car with square wheels. Make it smooth.

### 3. **Accessibility Matters**

Dark mode, font scaling, color contrast—everyone deserves a good experience.

### 4. **Fail Gracefully**

When things go wrong (and they will), tell the user what happened and how to fix it.

### 5. **Data Privacy is Sacred**

Collect only what's necessary. Protect it like it's your own.

---

## 🔮 Future Perspectives (The Crystal Ball Section)

### Short-term (Next 3 Months)

- [ ] **Push Notifications**: "Your subscription expires in 3 days!"
- [ ] **Offline Mode**: Cache everything, sync when online
- [ ] **Advanced Analytics**: Predictive models for bus usage
- [ ] **Multi-campus Support**: Because one campus isn't enough

### Mid-term (6-12 Months)

- [ ] **Real-time Bus Tracking**: GPS tracking for buses
- [ ] **Capacity Management**: "Bus is 80% full, consider next one"
- [ ] **Payment Integration**: Seamless subscription payments
- [ ] **Student Feedback**: Rate your bus experience

---

## 🤝 Contributing

We love contributions! Whether it's:

- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- 🧪 Test coverage

**Just remember**:

- Write clean code (your future self will thank you)
- Test your changes (seriously, please)
- Follow our coding style (consistency is key)
- Be nice in code reviews (we're all learning)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Translation: Do whatever you want with this code, but if it breaks, it's not our fault. 😄

---

## 🙏 Acknowledgments

**Special Thanks To:**

- ☕ **Coffee** - The real MVP
- 🌙 **Late nights** - Where the magic happened
- 🐛 **Stack Overflow** - Solving problems we didn't know we had
- 🔥 **Firebase Team** - For making backend easy(ish)
- 💙 **Flutter Community** - For the amazing packages
- 👥 **Beta Testers** - For breaking things before users could
- 🎓 **ICT University** - For the problem that inspired the solution

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/Joel-Fah/busin/issues)
- **Email**: joelfah2003@gmail.com

---

<div align="center">

## 🎤 *Mic Drop Moment*

</div>

```
We started with chaos.
We built with code.
We shipped with pride.

Paper forms? Archived.
Manual checks? Automated.
Clipboard stress? Eliminated.

What was once a daily struggle
Is now a tap, a scan, a smile.

Because great software doesn't just solve problems—
It makes you forget the problem ever existed.

BusIn: Where every line of code is a step toward
                simpler mornings,
                    smoother rides,
                        and a campus that just... works.
```

**We didn't just build an app. We built a movement.** 🚌✨

Now go forth and scan some QRs. Your clipboard-free future awaits.

---

**Made with 💙, ☕, and a healthy dose of determination**

*BusIn | 2026*

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Status](https://img.shields.io/badge/status-production-success)
![Vibes](https://img.shields.io/badge/vibes-immaculate-ff69b4)

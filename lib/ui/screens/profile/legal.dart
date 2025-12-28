import 'package:busin/api/legal_api.dart';
import 'package:busin/ui/components/widgets/buttons/tertiary_button.dart';
import 'package:busin/ui/components/widgets/loading_indicator.dart';
import 'package:busin/ui/components/widgets/markdown_styling.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  static const String routeName = '/legal';

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late final LegalApi _api;
  String? _content;
  String? _error;
  bool _loading = true;
  bool _usingFallback = false;

  // API endpoint - Update this with your actual legal.md hosting URL
  // For now, you can host this on GitHub raw, a CDN, or your own server
  // Example GitHub raw URL: https://raw.githubusercontent.com/username/repo/main/lib/docs/legal.md
  static const String _legalApiUrl = 'https://raw.githubusercontent.com/your-username/busin/main/lib/docs/legal.md';

  @override
  void initState() {
    super.initState();
    _api = LegalApi(baseUrl: _legalApiUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _usingFallback = false;
    });

    try {
      final data = await _api.fetchLegalMarkdown();
      if (!mounted) return;
      setState(() {
        _content = data;
        _loading = false;
      });
    } catch (e) {
      // Use fallback content on error
      if (!mounted) return;
      setState(() {
        _content = _fallbackLegalContent;
        _error = e.toString();
        _loading = false;
        _usingFallback = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.contain, child: const Text('Legal Information')),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          spacing: 8.0,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(),
            Text(
              'Loading legal information...',
              style: AppTextStyles.body.copyWith(
                color: themeController.isDark
                    ? lightColor.withValues(alpha: 0.75)
                    : seedColor.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Warning banner if using fallback
        if (_usingFallback && _error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.1),
              borderRadius: borderRadius * 2.0,
              border: Border.all(
                color: warningColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8.0,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      color: warningColor,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Using Offline Content',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Could not load the latest legal information. Showing cached version.',
                  style: AppTextStyles.small.copyWith(
                    color: themeController.isDark
                        ? lightColor.withValues(alpha: 0.7)
                        : seedColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8.0),
                TertiaryButton.icon(
                  onPressed: _load,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh,
                    size: 20.0,
                  ),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1, end: 0),

        // Content
        if (_content != null)
          MarkdownStyledView(data: _content!)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  // Fallback legal content
  static const String _fallbackLegalContent = '''
# Legal Information
- [x] Hellooo

**Last Updated:** December 28, 2025

## Terms of Service

### 1. Acceptance of Terms

By accessing and using BusIn ("the App"), you accept and agree to be bound by the terms and conditions of this agreement. If you do not agree to these terms, please do not use the App.

### 2. Description of Service

BusIn is a bus subscription management application designed for students and staff at ICT University, Cameroon. The App provides:

- Bus subscription management
- QR code-based access control
- Real-time subscription tracking
- Administrative tools for staff

### 3. User Accounts

#### 3.1 Registration
- Users must register with a valid ICT University email address
- Users are responsible for maintaining the confidentiality of their account credentials
- Users must provide accurate and complete information

#### 3.2 Account Types
- **Student**: For enrolled students requiring bus services
- **Staff/Admin**: For authorized university personnel managing the bus system

### 4. User Obligations

Users agree to:
- Provide accurate personal information
- Maintain the security of their account
- Not share their QR code or account access with others
- Use the service only for its intended purpose
- Comply with all applicable laws and university regulations

### 5. Subscriptions

#### 5.1 Subscription Process
- Students must submit a valid subscription request for each semester
- All subscriptions require administrative approval
- Subscriptions are valid only for the specified semester period

#### 5.2 Payment and Fees
- Subscription fees are determined by the university
- Payment must be completed before subscription activation
- Refund policies are subject to university regulations

### 6. QR Code Access

- Each student receives a unique QR code for bus access
- QR codes are non-transferable
- Sharing or duplicating QR codes is strictly prohibited
- Lost or compromised QR codes must be reported immediately

### 7. Data Collection and Privacy

#### 7.1 Information We Collect
- Personal identification (name, email, student ID)
- Contact information (phone number, address)
- Subscription history
- Scan/access logs
- Location data (for pickup point services)

#### 7.2 Use of Data
Your data is used to:
- Manage bus subscriptions
- Verify access rights
- Improve service quality
- Communicate important updates
- Generate usage statistics

#### 7.3 Data Protection
- We implement industry-standard security measures
- Personal data is encrypted and stored securely
- Access to data is restricted to authorized personnel only

#### 7.4 Data Sharing
We do not sell or share your personal information with third parties except:
- As required by law
- With university administration for legitimate purposes
- With service providers under strict confidentiality agreements

### 8. Intellectual Property

All content, features, and functionality of BusIn are owned by ICT University and are protected by international copyright, trademark, and other intellectual property laws.

### 9. Prohibited Conduct

Users must not:
- Violate any laws or regulations
- Infringe on others' rights
- Transmit harmful code or malware
- Attempt to gain unauthorized access
- Interfere with the App's operation
- Use automated systems to access the App
- Misrepresent identity or affiliation

### 10. Service Modifications

We reserve the right to:
- Modify or discontinue services at any time
- Update these terms without prior notice
- Suspend or terminate accounts for violations

### 11. Disclaimers

#### 11.1 Service Availability
- The App is provided "as is" without warranties
- We do not guarantee uninterrupted service
- Bus schedules and routes may change without notice

#### 11.2 Limitation of Liability
ICT University and BusIn are not liable for:
- Service interruptions or errors
- Lost data or access issues
- Indirect or consequential damages
- Issues arising from user negligence

### 12. Indemnification

Users agree to indemnify and hold harmless ICT University, its staff, and BusIn from any claims, damages, or expenses arising from misuse of the App or violation of these terms.

### 13. Termination

#### 13.1 By User
Users may terminate their account at any time through the App settings.

#### 13.2 By Us
We may suspend or terminate accounts that:
- Violate these terms
- Engage in fraudulent activity
- Are inactive for extended periods
- Pose security risks

### 14. Governing Law

These terms are governed by the laws of the Republic of Cameroon. Any disputes shall be resolved in the courts of Cameroon.

### 15. Contact Information

For questions about these terms or the App, contact:

**Email:** support@ictuniversity.edu.cm  
**Address:** ICT University, Yaounde, Cameroon

---

## Privacy Policy

### Information Collection

We collect information you provide directly:
- Account registration data
- Profile information
- Subscription details
- Communication preferences

### Automated Collection

We automatically collect:
- Device information
- Log data
- Usage statistics
- Location data (with permission)

### Cookies and Tracking

The App may use cookies and similar technologies to enhance user experience and gather analytics.

### Your Rights

You have the right to:
- Access your personal data
- Correct inaccurate information
- Request data deletion
- Opt-out of communications
- Export your data

### Data Retention

We retain your data for:
- Active accounts: Duration of enrollment
- Inactive accounts: Up to 2 years
- Legal requirements: As mandated by law

### Security Measures

- End-to-end encryption for sensitive data
- Regular security audits
- Secure cloud storage (Firebase/Supabase)
- Access controls and authentication

### Children's Privacy

BusIn is intended for university students (18+). We do not knowingly collect data from minors.

### Changes to Privacy Policy

We may update this policy periodically. Users will be notified of significant changes.

---

## Acceptable Use Policy

### Permitted Uses
- Managing bus subscriptions
- Accessing bus services
- Viewing personal subscription history
- Communicating with administrators

### Prohibited Uses
- Fraud or misrepresentation
- Harassment or abuse
- System manipulation
- Unauthorized access attempts
- Commercial use without permission

---

## Disclaimer

This legal document is provided as a fallback and may not reflect the most current terms. Please check for updates when connectivity is restored.

**For the most up-to-date legal information, please visit the official BusIn website or contact university administration.**
''';
}


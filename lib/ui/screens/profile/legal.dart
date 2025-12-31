import 'package:busin/api/legal_api.dart';
import 'package:busin/l10n/app_localizations.dart';
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

  static const String _legalApiUrl =
      'https://raw.githubusercontent.com/Joel-Fah/busin/refs/heads/main/lib/docs/legal.md';

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
        _content = localeController.locale.languageCode == 'en'
            ? _fallbackLegalContentEn
            : _fallbackLegalContentFr;
        _error = e.toString();
        _loading = false;
        _usingFallback = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.contain,
          child: Text(l10n.legalPage_appBar_title),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
            onPressed: _loading ? null : _load,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Center(
        child: Column(
          spacing: 8.0,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(),
            Text(
              l10n.legalPage_loadingInfo,
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
                        l10n.legalPage_offlineContent,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.legalPage_loadingError,
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
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

        // Content
        if (_content != null)
          MarkdownStyledView(
            data: _content!,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  // Fallback legal content
  static const String _fallbackLegalContentEn = '''
# Legal Information

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

  static const String _fallbackLegalContentFr = '''
  # Informations Légales

**Dernière mise à jour :** 28 décembre 2025

## Conditions Générales d'Utilisation

### 1. Acceptation des Conditions

En accédant et en utilisant BusIn (« l'Application »), vous acceptez d'être lié par les termes et conditions du présent accord. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'Application.

### 2. Description du Service

BusIn est une application de gestion d'abonnement de bus conçue pour les étudiants et le personnel de l'ICT University, Cameroun. L'Application propose :

- La gestion des abonnements de bus
- Le contrôle d'accès par code QR
- Le suivi d'abonnement en temps réel
- Des outils administratifs pour le personnel

### 3. Comptes Utilisateurs

#### 3.1 Inscription
- Les utilisateurs doivent s'inscrire avec une adresse e-mail valide de l'ICT University
- Les utilisateurs sont responsables du maintien de la confidentialité de leurs identifiants de compte
- Les utilisateurs doivent fournir des informations exactes et complètes

#### 3.2 Types de Comptes
- **Étudiant** : Pour les étudiants inscrits nécessitant les services de bus
- **Personnel/Admin** : Pour le personnel universitaire autorisé gérant le système de bus

### 4. Obligations de l'Utilisateur

Les utilisateurs s'engagent à :
- Fournir des informations personnelles exactes
- Maintenir la sécurité de leur compte
- Ne pas partager leur code QR ou l'accès à leur compte avec des tiers
- Utiliser le service uniquement aux fins prévues
- Se conformer à toutes les lois applicables et aux règlements de l'université

### 5. Abonnements

#### 5.1 Processus d'Abonnement
- Les étudiants doivent soumettre une demande d'abonnement valide pour chaque semestre
- Tous les abonnements nécessitent une approbation administrative
- Les abonnements ne sont valables que pour la période semestrielle spécifiée

#### 5.2 Paiement et Frais
- Les frais d'abonnement sont déterminés par l'université
- Le paiement doit être effectué avant l'activation de l'abonnement
- Les politiques de remboursement sont soumises aux règlements de l'université

### 6. Accès par Code QR

- Chaque étudiant reçoit un code QR unique pour l'accès au bus
- Les codes QR sont non transférables
- Le partage ou la duplication des codes QR est strictement interdit
- La perte ou la compromission d'un code QR doit être signalée immédiatement

### 7. Collecte de Données et Confidentialité

#### 7.1 Informations que nous collectons
- Identification personnelle (nom, email, matricule étudiant)
- Informations de contact (numéro de téléphone, adresse)
- Historique des abonnements
- Journaux de scan/accès
- Données de localisation (pour les services de points de ramassage)

#### 7.2 Utilisation des Données
Vos données sont utilisées pour :
- Gérer les abonnements de bus
- Vérifier les droits d'accès
- Améliorer la qualité du service
- Communiquer des mises à jour importantes
- Générer des statistiques d'utilisation

#### 7.3 Protection des Données
- Nous mettons en œuvre des mesures de sécurité conformes aux normes de l'industrie
- Les données personnelles sont cryptées et stockées de manière sécurisée
- L'accès aux données est limité au personnel autorisé uniquement

#### 7.4 Partage des Données
Nous ne vendons ni ne partageons vos informations personnelles avec des tiers, sauf :
- Tel que requis par la loi
- Avec l'administration de l'université à des fins légitimes
- Avec des prestataires de services sous des accords de confidentialité stricts

### 8. Propriété Intellectuelle

Tout le contenu, les caractéristiques et les fonctionnalités de BusIn sont la propriété de l'ICT University et sont protégés par les lois internationales sur le droit d'auteur, les marques de commerce et autres lois sur la propriété intellectuelle.

### 9. Conduite Prohibée

Les utilisateurs ne doivent pas :
- Violer les lois ou règlements
- Enfreindre les droits d'autrui
- Transmettre des codes malveillants ou des logiciels malveillants
- Tenter d'obtenir un accès non autorisé
- Entraver le fonctionnement de l'Application
- Utiliser des systèmes automatisés pour accéder à l'Application
- Usurper une identité ou une affiliation

### 10. Modifications du Service

Nous nous réservons le droit de :
- Modifier ou interrompre les services à tout moment
- Mettre à jour ces conditions sans préavis
- Suspendre ou résilier des comptes en cas de violation

### 11. Avis de Non-responsabilité

#### 11.1 Disponibilité du Service
- L'Application est fournie « en l'état » sans garantie
- Nous ne garantissons pas un service ininterrompu
- Les horaires et les itinéraires de bus peuvent changer sans préavis

#### 11.2 Limitation de Responsabilité
L'ICT University et BusIn ne sont pas responsables de :
- L'interruption de service ou des erreurs
- La perte de données ou des problèmes d'accès
- Des dommages indirects ou consécutifs
- Des problèmes découlant de la négligence de l'utilisateur

### 12. Indemnisation

Les utilisateurs acceptent d'indemniser et de dégager de toute responsabilité l'ICT University, son personnel et BusIn contre toute réclamation, dommage ou dépense découlant d'une mauvaise utilisation de l'Application ou de la violation de ces conditions.

### 13. Résiliation

#### 13.1 Par l'Utilisateur
Les utilisateurs peuvent résilier leur compte à tout moment via les paramètres de l'Application.

#### 13.2 Par Nous
Nous pouvons suspendre ou résilier les comptes qui :
- Violent ces conditions
- Se livrent à des activités frauduleuses
- Sont inactifs pendant de longues périodes
- Présentent des risques pour la sécurité

### 14. Loi Applicable

Ces conditions sont régies par les lois de la République du Cameroun. Tout litige sera résolu devant les tribunaux du Cameroun.

### 15. Coordonnées

Pour toute question concernant ces conditions ou l'Application, contactez :

**Email :** support@ictuniversity.edu.cm  
**Adresse :** ICT University, Yaoundé, Cameroun

---

## Politique de Confidentialité

### Collecte d'Informations

Nous collectons les informations que vous fournissez directement :
- Données d'inscription au compte
- Informations de profil
- Détails de l'abonnement
- Préférences de communication

### Collecte Automatisée

Nous collectons automatiquement :
- Informations sur l'appareil
- Données de journalisation (logs)
- Statistiques d'utilisation
- Données de localisation (avec votre permission)

### Cookies et Suivi

L'Application peut utiliser des cookies et des technologies similaires pour améliorer l'expérience utilisateur et recueillir des analyses.

### Vos Droits

Vous avez le droit de :
- Accéder à vos données personnelles
- Corriger les informations inexactes
- Demander la suppression des données
- Vous désabonner des communications
- Exporter vos données

### Conservation des Données

Nous conservons vos données pour :
- Comptes actifs : Durée de l'inscription
- Comptes inactifs : Jusqu'à 2 ans
- Exigences légales : Tel que mandaté par la loi

### Mesures de Sécurité

- Chiffrement de bout en bout pour les données sensibles
- Audits de sécurité réguliers
- Stockage cloud sécurisé (Firebase/Supabase)
- Contrôles d'accès et authentification

### Confidentialité des Enfants

BusIn est destiné aux étudiants universitaires (18+). Nous ne collectons pas sciemment de données auprès de mineurs.

### Modifications de la Politique de Confidentialité

Nous pouvons mettre à jour cette politique périodiquement. Les utilisateurs seront informés des changements importants.

---

## Politique d'Utilisation Acceptable

### Utilisations Autorisées
- Gérer les abonnements de bus
- Accéder aux services de bus
- Consulter l'historique personnel d'abonnement
- Communiquer avec les administrateurs

### Utilisations Interdites
- Fraude ou fausse déclaration
- Harcèlement ou abus
- Manipulation du système
- Tentatives d'accès non autorisé
- Utilisation commerciale sans autorisation

---

## Avis de Non-responsabilité

Ce document juridique est fourni à titre de secours et peut ne pas refléter les conditions les plus récentes. Veuillez vérifier les mises à jour lorsque la connexion est rétablie.

**Pour les informations juridiques les plus à jour, veuillez consulter le site officiel de BusIn ou contacter l'administration de l'université.**
  ''';
}

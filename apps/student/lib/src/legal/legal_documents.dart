/// The three legal documents, bundled with the app so they open offline and never depend on a web address that can move.
/// Written without a school's name: the page shows which school it applies to, so the same text serves every school.
///
/// This is a working draft of the plain-language terms. The owner and the school must have it reviewed before release.
enum LegalDoc { terms, privacy, acceptableUse }

/// One titled part of a document: some paragraphs, then an optional list.
class LegalSection {
  const LegalSection(this.title, {this.paragraphs = const [], this.bullets = const []});

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  int get words => [title, ...paragraphs, ...bullets].fold(0, (sum, line) => sum + line.split(RegExp(r'\s+')).length);
}

class LegalDocument {
  const LegalDocument({required this.highlights, required this.sections});

  /// Three or four plain sentences that say what matters, shown above the full text.
  final List<String> highlights;
  final List<LegalSection> sections;

  /// A reading time at 200 words a minute, never under one.
  int get minutes {
    final words = sections.fold(0, (sum, s) => sum + s.words) + highlights.fold(0, (sum, h) => sum + h.split(RegExp(r'\s+')).length);
    return (words / 200).ceil().clamp(1, 99);
  }
}

/// When the texts were last changed.
final legalUpdatedAt = DateTime.utc(2026, 11, 6);

/// The document in [languageCode] ('fr' or anything else for English).
LegalDocument legalDocument(LegalDoc doc, String languageCode) {
  final french = languageCode == 'fr';
  return switch (doc) {
    LegalDoc.terms => french ? _termsFr : _termsEn,
    LegalDoc.privacy => french ? _privacyFr : _privacyEn,
    LegalDoc.acceptableUse => french ? _acceptableFr : _acceptableEn,
  };
}

const _termsEn = LegalDocument(
  highlights: [
    'BusIn lets you ask your school for a bus subscription and board with a personal code.',
    'Your school decides on each request and can take a subscription back.',
    'Your boarding code is yours alone. Do not share it.',
    'The service can change or stop, and rides are your school\'s responsibility.',
  ],
  sections: [
    LegalSection('Using BusIn', paragraphs: [
      'By signing in you accept these terms. If you do not accept them, please do not use the app.',
      'BusIn is run for your school. It helps the school manage bus subscriptions and check who boards.',
    ]),
    LegalSection('Your account', paragraphs: [
      'You sign in with the Google account your school accepts. Only people the school allows can use the app.',
    ], bullets: [
      'Keep your account secure and do not let anyone else use it.',
      'Give accurate details and keep them up to date.',
      'Tell your school if you think someone else has used your account or your code.',
    ]),
    LegalSection('Subscriptions', paragraphs: [
      'You ask for a subscription for a semester and attach proof of payment. Your school reviews the request and approves or declines it, with a reason when it declines.',
    ], bullets: [
      'A subscription is valid for the semester it was approved for.',
      'Your school can revoke a subscription, and can give it back later. Each step is kept in your history.',
      'Fees, payment and refunds are set by your school, not by the app.',
    ]),
    LegalSection('Your boarding code', bullets: [
      'The code identifies you. It is personal and cannot be passed to someone else.',
      'It changes every few seconds. A screenshot or a copy will not work, and the app blocks screenshots on that screen where the phone allows it.',
      'When your subscription is revoked, the code stops working at once.',
    ]),
    LegalSection('The service', paragraphs: [
      'BusIn is provided as it is. We work to keep it available, but we cannot promise that it will always work, that bus times and positions will always be exact, or that it will never make a mistake.',
      'The bus ride itself is provided by your school or its transport partner. BusIn is not responsible for delays, changes of route or events during the trip.',
    ]),
    LegalSection('Changes and ending', bullets: [
      'We may improve, change or stop parts of the service. When a change matters to you, the app tells you.',
      'Your school may suspend an account that breaks these terms or the acceptable use rules.',
      'You can stop using the app at any time. Ask your school to remove your account and data.',
    ]),
    LegalSection('Law and contact', paragraphs: [
      'These terms follow the law that applies where your school operates. For any question, contact your school\'s administration.',
    ]),
  ],
);

const _termsFr = LegalDocument(
  highlights: [
    'BusIn vous permet de demander un abonnement de bus à votre école et de monter à bord avec un code personnel.',
    'Votre école décide de chaque demande et peut retirer un abonnement.',
    'Votre code d\'embarquement est strictement personnel. Ne le partagez pas.',
    'Le service peut évoluer ou s\'arrêter, et les trajets relèvent de votre école.',
  ],
  sections: [
    LegalSection('Utiliser BusIn', paragraphs: [
      'En vous connectant, vous acceptez ces conditions. Si vous ne les acceptez pas, n\'utilisez pas l\'application.',
      'BusIn est exploitée pour votre école. Elle aide l\'école à gérer les abonnements de bus et à vérifier qui monte à bord.',
    ]),
    LegalSection('Votre compte', paragraphs: [
      'Vous vous connectez avec le compte Google que votre école accepte. Seules les personnes autorisées par l\'école peuvent utiliser l\'application.',
    ], bullets: [
      'Protégez votre compte et n\'en laissez l\'usage à personne.',
      'Donnez des informations exactes et tenez-les à jour.',
      'Prévenez votre école si vous pensez que quelqu\'un a utilisé votre compte ou votre code.',
    ]),
    LegalSection('Abonnements', paragraphs: [
      'Vous demandez un abonnement pour un semestre et joignez une preuve de paiement. Votre école examine la demande et l\'approuve ou la refuse, en indiquant un motif en cas de refus.',
    ], bullets: [
      'Un abonnement est valable pour le semestre pour lequel il a été approuvé.',
      'Votre école peut révoquer un abonnement, et le rétablir plus tard. Chaque étape est conservée dans votre historique.',
      'Les frais, le paiement et les remboursements sont fixés par votre école, pas par l\'application.',
    ]),
    LegalSection('Votre code d\'embarquement', bullets: [
      'Le code vous identifie. Il est personnel et ne peut pas être cédé.',
      'Il change toutes les quelques secondes. Une capture d\'écran ou une copie ne fonctionnera pas, et l\'application bloque les captures sur cet écran lorsque le téléphone le permet.',
      'Quand votre abonnement est révoqué, le code cesse de fonctionner immédiatement.',
    ]),
    LegalSection('Le service', paragraphs: [
      'BusIn est fournie telle quelle. Nous faisons le nécessaire pour qu\'elle reste disponible, mais nous ne pouvons pas promettre qu\'elle fonctionnera toujours, que les horaires et positions des bus seront toujours exacts, ou qu\'elle ne fera jamais d\'erreur.',
      'Le trajet en bus est assuré par votre école ou son partenaire de transport. BusIn n\'est pas responsable des retards, des changements d\'itinéraire ou des événements survenus pendant le trajet.',
    ]),
    LegalSection('Évolutions et fin d\'usage', bullets: [
      'Nous pouvons améliorer, modifier ou arrêter des parties du service. Quand un changement vous concerne, l\'application vous le dit.',
      'Votre école peut suspendre un compte qui enfreint ces conditions ou les règles d\'usage acceptable.',
      'Vous pouvez cesser d\'utiliser l\'application à tout moment. Demandez à votre école de supprimer votre compte et vos données.',
    ]),
    LegalSection('Droit applicable et contact', paragraphs: [
      'Ces conditions suivent le droit applicable là où votre école exerce son activité. Pour toute question, contactez l\'administration de votre école.',
    ]),
  ],
);

const _privacyEn = LegalDocument(
  highlights: [
    'We keep only what is needed to run your bus subscription.',
    'We never sell your data, and we never track your phone\'s location.',
    'Your school can see your details and your boardings. Other students cannot.',
    'You can correct your details in the profile, and ask your school to delete your account.',
  ],
  sections: [
    LegalSection('What we keep', paragraphs: ['When you use BusIn we hold:'], bullets: [
      'Your name, school email and profile picture, from your Google account.',
      'Details you add: matricule, phone number, faculty, department, degree level and your usual stop.',
      'Your subscription requests, the proof of payment you upload, and each decision with its reason.',
      'Your boardings: when and on which trip you boarded.',
      'A device token, if you allow notifications, so that we can send them.',
      'Your area, only if you add one in My area: a spot rounded to about 500 metres and its name, never your exact address.',
    ]),
    LegalSection('Why we keep it', bullets: [
      'To let your school review your request and decide.',
      'To check your right to board when your code is scanned.',
      'To show you your own history and tell you when something changes.',
      'To give your school the figures it needs to run the buses.',
      'If you add your area: to help your school place stops and plan routes. Your school only sees how many students live in each zone, and only zones with at least five students.',
    ]),
    LegalSection('What we do not collect', bullets: [
      'Your phone\'s location while you use the app. The map shows the position of buses, not yours. The only reading is the one you ask for in My area: once, approximate, rounded to about 500 metres.',
      'Your contacts, photos or files, apart from the proof of payment you choose to upload.',
      'Advertising profiles. There is no advertising in BusIn.',
    ]),
    LegalSection('Who can see it', bullets: [
      'You see your own data.',
      'Your school\'s administrators and staff see what they need for their role: administrators your details, requests and boardings; staff the scan result at the door.',
      'Other students never see your data, and no school sees another school\'s data.',
      'We do not sell your data or share it with advertisers. We use service providers to run the app (hosting, sign-in, notifications) under the same duty of care.',
    ]),
    LegalSection('How it is protected', bullets: [
      'Access rules are enforced on the server, for every request, for every school.',
      'Your boarding code secret is kept in your phone\'s secure storage and never shown.',
      'Proof of payment is stored privately and opened only through short-lived links.',
      'Connections to the service are encrypted.',
    ]),
    LegalSection('How long we keep it', paragraphs: [
      'Your account and history are kept while you are enrolled and use the service, and as long as your school needs them for its records or the law requires. Ask your school how long it keeps them.',
    ]),
    LegalSection('Your choices', bullets: [
      'Correct your details in the profile at any time.',
      'Turn notifications off in your phone settings.',
      'Change or remove your area in My area at any time. Place search runs on BusIn\'s own servers, on a copy of OpenStreetMap: what you type is not sent to anyone else.',
      'Ask your school for a copy of your data, or to delete your account and data.',
    ]),
    LegalSection('Changes to this policy', paragraphs: [
      'If we change what we collect or why, we update this page and the app tells you.',
    ]),
  ],
);

const _privacyFr = LegalDocument(
  highlights: [
    'Nous ne gardons que ce qui est nécessaire pour gérer votre abonnement de bus.',
    'Nous ne vendons jamais vos données et nous ne suivons jamais la position de votre téléphone.',
    'Votre école voit vos informations et vos embarquements. Les autres étudiants, non.',
    'Vous pouvez corriger vos informations dans le profil et demander à votre école de supprimer votre compte.',
  ],
  sections: [
    LegalSection('Ce que nous gardons', paragraphs: ['Quand vous utilisez BusIn, nous conservons :'], bullets: [
      'Votre nom, votre e-mail scolaire et votre photo de profil, issus de votre compte Google.',
      'Les informations que vous ajoutez : matricule, téléphone, faculté, département, niveau d\'études et votre arrêt habituel.',
      'Vos demandes d\'abonnement, la preuve de paiement que vous envoyez, et chaque décision avec son motif.',
      'Vos embarquements : quand et sur quel trajet vous êtes monté.',
      'Un jeton d\'appareil, si vous autorisez les notifications, pour pouvoir les envoyer.',
      'Votre zone, seulement si vous en ajoutez une dans Ma zone : un point arrondi à environ 500 mètres et son nom, jamais votre adresse exacte.',
    ]),
    LegalSection('Pourquoi nous le gardons', bullets: [
      'Pour que votre école examine votre demande et décide.',
      'Pour vérifier votre droit de monter à bord quand votre code est scanné.',
      'Pour vous montrer votre propre historique et vous prévenir quand quelque chose change.',
      'Pour donner à votre école les chiffres dont elle a besoin pour faire rouler les bus.',
      'Si vous ajoutez votre zone : pour aider votre école à placer les arrêts et à prévoir les trajets. Votre école ne voit que le nombre d\'étudiants par zone, et seulement les zones d\'au moins cinq étudiants.',
    ]),
    LegalSection('Ce que nous ne collectons pas', bullets: [
      'La position de votre téléphone pendant que vous utilisez l\'application. La carte montre la position des bus, pas la vôtre. La seule lecture est celle que vous demandez dans Ma zone : une fois, approximative, arrondie à environ 500 mètres.',
      'Vos contacts, photos ou fichiers, en dehors de la preuve de paiement que vous choisissez d\'envoyer.',
      'Des profils publicitaires. Il n\'y a aucune publicité dans BusIn.',
    ]),
    LegalSection('Qui peut le voir', bullets: [
      'Vous voyez vos propres données.',
      'Les administrateurs et le personnel de votre école voient ce qui est nécessaire à leur rôle : les administrateurs vos informations, demandes et embarquements ; le personnel le résultat du scan à la porte.',
      'Les autres étudiants ne voient jamais vos données, et aucune école ne voit celles d\'une autre.',
      'Nous ne vendons pas vos données et ne les partageons pas avec des annonceurs. Nous faisons appel à des prestataires pour faire fonctionner l\'application (hébergement, connexion, notifications), soumis au même devoir de précaution.',
    ]),
    LegalSection('Comment elles sont protégées', bullets: [
      'Les règles d\'accès sont appliquées sur le serveur, pour chaque requête et chaque école.',
      'Le secret de votre code d\'embarquement est gardé dans le stockage sécurisé de votre téléphone et n\'est jamais affiché.',
      'Les preuves de paiement sont stockées de façon privée et ouvertes seulement par des liens de courte durée.',
      'Les connexions au service sont chiffrées.',
    ]),
    LegalSection('Combien de temps', paragraphs: [
      'Votre compte et votre historique sont conservés tant que vous êtes inscrit et utilisez le service, et aussi longtemps que votre école en a besoin pour ses registres ou que la loi l\'exige. Demandez à votre école combien de temps elle les garde.',
    ]),
    LegalSection('Vos choix', bullets: [
      'Corrigez vos informations dans le profil à tout moment.',
      'Désactivez les notifications dans les réglages de votre téléphone.',
      'Modifiez ou supprimez votre zone dans Ma zone à tout moment. La recherche de lieux se fait sur les serveurs de BusIn, sur une copie d\'OpenStreetMap : ce que vous tapez n\'est envoyé à personne d\'autre.',
      'Demandez à votre école une copie de vos données, ou la suppression de votre compte et de vos données.',
    ]),
    LegalSection('Modifications de cette politique', paragraphs: [
      'Si nous changeons ce que nous collectons ou pourquoi, nous mettons cette page à jour et l\'application vous le dit.',
    ]),
  ],
);

const _acceptableEn = LegalDocument(
  highlights: [
    'Use BusIn only to get on your own school bus with your own subscription.',
    'No sharing codes, no fake proof, no tampering with the service.',
    'Be respectful to staff and drivers who help you.',
  ],
  sections: [
    LegalSection('What is welcome', bullets: [
      'Asking for your own subscription and keeping your details true.',
      'Showing your own boarding code to board.',
      'Checking your history and the position of the buses.',
      'Telling your school when something looks wrong.',
    ]),
    LegalSection('What is not allowed', bullets: [
      'Sharing, selling, lending or copying a boarding code, or boarding on someone else\'s subscription.',
      'Uploading a proof of payment that is false, altered or not yours.',
      'Pretending to be someone else, or giving false details.',
      'Trying to reach data that is not yours, or to get around the app\'s protections.',
      'Using automated tools to call the service, or overloading it.',
      'Insulting, threatening or harassing staff, drivers or other students.',
    ]),
    LegalSection('If something goes wrong', paragraphs: [
      'If the rules are broken, your school can revoke your subscription, suspend your account, and apply its own disciplinary rules. Serious abuse may be reported to the authorities.',
      'If you find a weakness in the app, please tell your school and do not use it.',
    ]),
  ],
);

const _acceptableFr = LegalDocument(
  highlights: [
    'Utilisez BusIn uniquement pour monter dans le bus de votre école avec votre propre abonnement.',
    'Pas de partage de code, pas de faux justificatif, pas de manipulation du service.',
    'Soyez respectueux envers le personnel et les chauffeurs qui vous aident.',
  ],
  sections: [
    LegalSection('Ce qui est bienvenu', bullets: [
      'Demander votre propre abonnement et garder vos informations exactes.',
      'Présenter votre propre code d\'embarquement pour monter à bord.',
      'Consulter votre historique et la position des bus.',
      'Signaler à votre école quand quelque chose semble anormal.',
    ]),
    LegalSection('Ce qui n\'est pas permis', bullets: [
      'Partager, vendre, prêter ou copier un code d\'embarquement, ou monter avec l\'abonnement de quelqu\'un d\'autre.',
      'Envoyer une preuve de paiement fausse, modifiée ou qui n\'est pas la vôtre.',
      'Se faire passer pour quelqu\'un d\'autre, ou donner de fausses informations.',
      'Essayer d\'accéder à des données qui ne sont pas les vôtres, ou de contourner les protections de l\'application.',
      'Utiliser des outils automatisés pour appeler le service, ou le surcharger.',
      'Insulter, menacer ou harceler le personnel, les chauffeurs ou d\'autres étudiants.',
    ]),
    LegalSection('Si quelque chose ne va pas', paragraphs: [
      'En cas de manquement, votre école peut révoquer votre abonnement, suspendre votre compte et appliquer son propre règlement disciplinaire. Les abus graves peuvent être signalés aux autorités.',
      'Si vous découvrez une faille dans l\'application, signalez-la à votre école et ne l\'exploitez pas.',
    ]),
  ],
);

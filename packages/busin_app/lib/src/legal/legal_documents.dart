/// The legal documents, shared by the student and ops apps and bundled with them so they open offline and never depend on a web address that can move.
/// Written without a school's name: the page shows which school it applies to, so the same text serves every school.
///
/// This is a working draft of the plain-language terms. The owner and the school must have it reviewed before release.
enum LegalDoc { terms, privacy, acceptableUse, payments }

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
final legalUpdatedAt = DateTime.utc(2026, 11, 27);

/// The document in [languageCode] ('fr' or anything else for English).
LegalDocument legalDocument(LegalDoc doc, String languageCode) {
  final french = languageCode == 'fr';
  return switch (doc) {
    LegalDoc.terms => french ? _termsFr : _termsEn,
    LegalDoc.privacy => french ? _privacyFr : _privacyEn,
    LegalDoc.acceptableUse => french ? _acceptableFr : _acceptableEn,
    LegalDoc.payments => french ? _paymentsFr : _paymentsEn,
  };
}

const _termsEn = LegalDocument(
  highlights: [
    'BusIn lets you ask your school for a bus subscription and board with a personal code.',
    'Your school decides on each request and can take a subscription back.',
      'Where your school offers it, you can pay in the app by mobile money; your school decides refunds.',
    'Your boarding code is yours alone. Do not share it.',
    'The service can change or stop, and rides are your school\'s responsibility.',
  ],
  sections: [
    LegalSection('Using BusIn', paragraphs: [
      'By signing in you accept these terms. If you do not accept them, please do not use the app.',
      'BusIn is run for your school. It helps the school manage bus subscriptions and check who boards.',
    ]),
    LegalSection('Your account', paragraphs: [
      'You sign in with a Google account. With your school email you join your school directly. Where your school also accepts other addresses, you can join with a personal account: your school then checks that you are one of its students before letting you in.',
    ], bullets: [
      'Keep your account secure and do not let anyone else use it.',
      'Give accurate details and keep them up to date.',
      'Tell your school if you think someone else has used your account or your code.',
    ]),
    LegalSection('Subscriptions', paragraphs: [
      'You ask for a subscription for a semester (or a month, if your school bills by the month). Where your school offers it, you pay in the app by mobile money and the request is approved as soon as the payment goes through. Otherwise you attach proof of a payment made to your school, which reviews the request and approves or declines it, with a reason when it declines.',
    ], bullets: [
      'A subscription is valid for the semester it was approved for.',
      'Your school can revoke a subscription, and can give it back later. Each step is kept in your history.',
      'Your school sets the price and decides refunds. Paying by mobile money, and refunds, follow the payments and refunds policy.',
    ]),
    LegalSection('Paying by mobile money', bullets: [
      'Where your school offers it, you can pay with MTN Mobile Money or Orange Money. BusIn collects the payment for your school through pawaPay, a payment company, and your operator, and passes the school\'s share on to it. Your school remains the provider of the bus service.',
      'Before you pay, the app shows the price, any mobile money fee and the total. The fee covers the cost of moving the money; whether it applies is your school\'s choice.',
      'You confirm the payment on your phone with your operator\'s PIN. It is complete only when your operator confirms it. If it does not go through, nothing is taken.',
      'Each payment gets a numbered receipt in the app. You can ask your school for a refund from it, with a reason; the mobile money fee is not refunded. A payment BusIn cannot use is refunded in full, fee included.',
    ]),
    LegalSection('Your boarding code', bullets: [
      'The code identifies you. It is personal and cannot be passed to someone else.',
      'It changes every few seconds. A screenshot or a copy will not work, and the app blocks screenshots on that screen where the phone allows it.',
      'When your subscription is revoked, the code stops working at once.',
    ]),
    LegalSection('The service', paragraphs: [
      'BusIn is provided as it is. We work to keep it available, but we cannot promise that it will always work, that bus positions, arrival estimates and the updates on My bus will always be exact, or that it will never make a mistake. They are there to help you, not a promise of when the bus comes.',
      'The bus ride itself is provided by your school or its transport partner. BusIn is not responsible for delays, changes of route or events during the trip.',
    ]),
    LegalSection('Changes and ending', bullets: [
      'We may improve, change or stop parts of the service. When a change matters to you, the app tells you.',
      'Your school may suspend an account that breaks these terms or the acceptable use rules.',
      'You can stop using the app at any time, and delete your account yourself from your profile: it is erased 7 days later, and your school keeps its records without your name.',
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
      'Si votre école le propose, vous pouvez payer dans l\'application par mobile money ; votre école décide des remboursements.',
    'Votre code d\'embarquement est strictement personnel. Ne le partagez pas.',
    'Le service peut évoluer ou s\'arrêter, et les trajets relèvent de votre école.',
  ],
  sections: [
    LegalSection('Utiliser BusIn', paragraphs: [
      'En vous connectant, vous acceptez ces conditions. Si vous ne les acceptez pas, n\'utilisez pas l\'application.',
      'BusIn est exploitée pour votre école. Elle aide l\'école à gérer les abonnements de bus et à vérifier qui monte à bord.',
    ]),
    LegalSection('Votre compte', paragraphs: [
      'Vous vous connectez avec un compte Google. Avec votre e-mail scolaire, vous rejoignez directement votre école. Si votre école accepte aussi d\'autres adresses, vous pouvez la rejoindre avec un compte personnel : votre école vérifie alors que vous êtes bien l\'un de ses étudiants avant de vous accepter.',
    ], bullets: [
      'Protégez votre compte et n\'en laissez l\'usage à personne.',
      'Donnez des informations exactes et tenez-les à jour.',
      'Prévenez votre école si vous pensez que quelqu\'un a utilisé votre compte ou votre code.',
    ]),
    LegalSection('Abonnements', paragraphs: [
      'Vous demandez un abonnement pour un semestre (ou un mois, si votre école facture au mois). Si votre école le propose, vous payez dans l\'application par mobile money et la demande est approuvée dès que le paiement passe. Sinon, vous joignez la preuve d\'un paiement fait à votre école, qui examine la demande et l\'approuve ou la refuse, en indiquant un motif en cas de refus.',
    ], bullets: [
      'Un abonnement est valable pour le semestre pour lequel il a été approuvé.',
      'Votre école peut révoquer un abonnement, et le rétablir plus tard. Chaque étape est conservée dans votre historique.',
      'Votre école fixe le prix et décide des remboursements. Le paiement par mobile money et les remboursements suivent la politique de paiement et de remboursement.',
    ]),
    LegalSection('Payer par mobile money', bullets: [
      'Si votre école le propose, vous pouvez payer avec MTN Mobile Money ou Orange Money. BusIn encaisse le paiement pour votre école par l\'intermédiaire de pawaPay, une société de paiement, et de votre opérateur, et reverse à l\'école sa part. Votre école reste le fournisseur du service de bus.',
      'Avant de payer, l\'application affiche le prix, les éventuels frais mobile money et le total. Les frais couvrent le coût du transfert de l\'argent ; votre école décide s\'ils s\'appliquent.',
      'Vous confirmez le paiement sur votre téléphone avec le code de votre opérateur. Il n\'est terminé que lorsque votre opérateur le confirme. S\'il n\'aboutit pas, rien n\'est prélevé.',
      'Chaque paiement reçoit un reçu numéroté dans l\'application. Vous pouvez y demander un remboursement à votre école, avec un motif ; les frais mobile money ne sont pas remboursés. Un paiement que BusIn ne peut pas utiliser est remboursé en entier, frais compris.',
    ]),
    LegalSection('Votre code d\'embarquement', bullets: [
      'Le code vous identifie. Il est personnel et ne peut pas être cédé.',
      'Il change toutes les quelques secondes. Une capture d\'écran ou une copie ne fonctionnera pas, et l\'application bloque les captures sur cet écran lorsque le téléphone le permet.',
      'Quand votre abonnement est révoqué, le code cesse de fonctionner immédiatement.',
    ]),
    LegalSection('Le service', paragraphs: [
      'BusIn est fournie telle quelle. Nous faisons le nécessaire pour qu\'elle reste disponible, mais nous ne pouvons pas promettre qu\'elle fonctionnera toujours, que les positions des bus, les estimations d\'arrivée et les infos de Mon bus seront toujours exactes, ou qu\'elle ne fera jamais d\'erreur. Elles sont là pour vous aider, pas pour garantir l\'heure du bus.',
      'Le trajet en bus est assuré par votre école ou son partenaire de transport. BusIn n\'est pas responsable des retards, des changements d\'itinéraire ou des événements survenus pendant le trajet.',
    ]),
    LegalSection('Évolutions et fin d\'usage', bullets: [
      'Nous pouvons améliorer, modifier ou arrêter des parties du service. Quand un changement vous concerne, l\'application vous le dit.',
      'Votre école peut suspendre un compte qui enfreint ces conditions ou les règles d\'usage acceptable.',
      'Vous pouvez cesser d\'utiliser l\'application à tout moment, et supprimer vous-même votre compte depuis votre profil : il est effacé 7 jours plus tard, et votre école garde ses registres sans votre nom.',
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
    'Your school can see your details and your boardings. Other students see nothing about you, unless you join the streaks board.',
    'You can correct your details in the profile, and delete your account yourself there.',
  ],
  sections: [
    LegalSection('What we keep', paragraphs: ['When you use BusIn we hold:'], bullets: [
      'Your name, email and profile picture, from your Google account.',
      'Details you add: matricule, phone number, faculty, department, degree level, your usual stop and, only if you choose to give it, your gender (seen by you and your school\'s administrators, never by staff or other students; you can clear it at any time).',
      'Your subscription requests, the proof of payment you upload, and each decision with its reason.',
      'If you pay in the app: the operator, the number that paid (kept partly hidden, such as 2376*****789), the amounts, the operator\'s reference, the receipt and any refund. Your full number goes to pawaPay and your operator to make the payment; BusIn does not keep it.',
      'Your boardings: when, on which trip and at which stop you boarded (the stop nearest to the staff phone that scanned you).',
      'A device token, if you allow notifications, so that we can send them, and which notifications you chose.',
      'Your streak, only if you turn streaks on.',
      'Your area, only if you add one in My area: a spot rounded to about 500 metres and its name, never your exact address.',
      'If the phone app crashes, a crash report: what went wrong in the app, the phone model and system version, the app version and whether you are a student or staff. Never your name, email, code or location. Only from the apps you install, not the web app.',
    ]),
    LegalSection('Why we keep it', bullets: [
      'To let your school review your request and decide.',
      'To take your payments and refunds, give you receipts and keep your school\'s and BusIn\'s accounts.',
      'To check your right to board when your code is scanned.',
      'To show you your own history and tell you when something changes.',
      'To give your school the figures it needs to run the buses: how many board at each stop and how full the buses get. These are counts, not lists of names.',
      'If you add your area: to help your school place stops and plan routes. Your school only sees how many students live in each zone and how far they are from their stops, and only for groups of at least five students.',
    ]),
    LegalSection('What we do not collect', bullets: [
      'Your phone\'s location in the background. The app reads it only when you ask: once in My area (approximate, rounded to about 500 metres and kept), and on My bus while you use Show me (to place you next to your stop and the bus; it stays on your phone and is never sent or kept).',
      'What the bus is doing on My bus (at a stop, stopped, near your stop): your phone works it out while you look, and nothing is kept.',
      'Your contacts, photos or files, apart from the proof of payment you choose to upload.',
      'Advertising profiles. There is no advertising in BusIn.',
    ]),
    LegalSection('Who can see it', bullets: [
      'You see your own data.',
      'Your school\'s administrators and staff see what they need for their role: administrators your details, requests and boardings; staff at the door your name, photo, matricule and stop when your code is scanned.',
      'So the door works without a signal, a staff phone keeps, for that day only, the list of today\'s riders with those same details and a key valid for that day. It is deleted when the staff member signs out, and replaced the next day.',
      'Other students see nothing about you. If you turn streaks on, students of your school see your first name, the initial of your last name, your picture and your streak on the board; turn streaks off to leave it.',
      'No school sees another school\'s data.',
      'We do not sell your data or share it with advertisers. We use service providers to run the app (hosting, sign-in, notifications, crash reports) under the same duty of care.',
      'When you pay in the app, pawaPay (a payment company) and your mobile money operator (MTN or Orange) receive your number and the amount to process the payment or a refund, under their own terms and the law on payments.',
    ]),
    LegalSection('If you are staff or a driver', bullets: [
      'The scans you make are recorded with your account, the time and the nearest stop.',
      'While you share the bus position during a trip you run, your phone sends where it is every few seconds, with a notification showing the whole time. Subscribers and administrators of your school see the bus; administrators can also see a thinned trace of the trip, kept for arrival estimates.',
      'Sharing stops when the trip ends or when you turn it off. Your phone\'s position is never read outside a trip you run.',
      'Your school can add you by email, including a personal address. The role it gives you comes with that account.',
    ]),
    LegalSection('How it is protected', bullets: [
      'Access rules are enforced on the server, for every request, for every school.',
      'Your boarding code secret is kept in your phone\'s secure storage and never shown. The day key on a staff phone cannot make your code for any other day.',
      'Proof of payment is stored privately and opened only through short-lived links.',
      'Connections to the service are encrypted.',
    ]),
    LegalSection('How long we keep it', paragraphs: [
      'Your account and history are kept while you are enrolled and use the service, and as long as your school needs them for its records or the law requires. Ask your school how long it keeps them. Payments, refunds and receipts are kept for 10 years, as accounting law requires, also after your account is deleted, without your name.',
    ]),
    LegalSection('Your choices', bullets: [
      'Correct your details in the profile at any time.',
      'Turn notifications off in your phone settings.',
      'Change or remove your area in My area at any time. Place search runs on BusIn\'s own servers, on a copy of OpenStreetMap: what you type is not sent to anyone else.',
      'Ask your school for a copy of your data. Delete your account yourself from your profile, or, if you cannot sign in any more, ask from the BusIn website (Delete your account, at the bottom of the home page): your name, contact details, photo, matricule, home area and payment proofs are erased 7 days later, and your school keeps its records without your name.',
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
    'Votre école voit vos informations et vos embarquements. Les autres étudiants ne voient rien de vous, sauf si vous rejoignez le tableau des séries.',
    'Vous pouvez corriger vos informations dans le profil, et y supprimer vous-même votre compte.',
  ],
  sections: [
    LegalSection('Ce que nous gardons', paragraphs: ['Quand vous utilisez BusIn, nous conservons :'], bullets: [
      'Votre nom, votre e-mail et votre photo de profil, issus de votre compte Google.',
      'Les informations que vous ajoutez : matricule, téléphone, faculté, département, niveau d\'études, votre arrêt habituel et, seulement si vous choisissez de l\'indiquer, votre genre (vu par vous et les administrateurs de votre école, jamais par le personnel ni les autres étudiants ; vous pouvez l\'effacer à tout moment).',
      'Vos demandes d\'abonnement, la preuve de paiement que vous envoyez, et chaque décision avec son motif.',
      'Si vous payez dans l\'application : l\'opérateur, le numéro qui a payé (gardé en partie masqué, par exemple 2376*****789), les montants, la référence de l\'opérateur, le reçu et un éventuel remboursement. Votre numéro complet est transmis à pawaPay et à votre opérateur pour effectuer le paiement ; BusIn ne le garde pas.',
      'Vos embarquements : quand, sur quel trajet et à quel arrêt vous êtes monté (l\'arrêt le plus proche du téléphone du personnel qui vous a scanné).',
      'Un jeton d\'appareil, si vous autorisez les notifications, pour pouvoir les envoyer, et les notifications que vous avez choisies.',
      'Votre série, seulement si vous activez les séries.',
      'Votre zone, seulement si vous en ajoutez une dans Ma zone : un point arrondi à environ 500 mètres et son nom, jamais votre adresse exacte.',
      'Si l\'application mobile plante, un rapport de plantage : ce qui s\'est mal passé dans l\'application, le modèle et la version du téléphone, la version de l\'application et si vous êtes étudiant ou membre du personnel. Jamais votre nom, votre e-mail, votre code ni votre position. Seulement depuis les applications installées, pas l\'application web.',
    ]),
    LegalSection('Pourquoi nous le gardons', bullets: [
      'Pour que votre école examine votre demande et décide.',
      'Pour encaisser vos paiements et remboursements, vous remettre des reçus et tenir les comptes de votre école et de BusIn.',
      'Pour vérifier votre droit de monter à bord quand votre code est scanné.',
      'Pour vous montrer votre propre historique et vous prévenir quand quelque chose change.',
      'Pour donner à votre école les chiffres dont elle a besoin pour faire rouler les bus : combien montent à chaque arrêt et à quel point les bus se remplissent. Ce sont des comptes, pas des listes de noms.',
      'Si vous ajoutez votre zone : pour aider votre école à placer les arrêts et à prévoir les trajets. Votre école ne voit que le nombre d\'étudiants par zone et leur distance aux arrêts, et seulement pour des groupes d\'au moins cinq étudiants.',
    ]),
    LegalSection('Ce que nous ne collectons pas', bullets: [
      'La position de votre téléphone en arrière-plan. L\'application la lit seulement quand vous le demandez : une fois dans Ma zone (approximative, arrondie à environ 500 mètres et conservée), et dans Mon bus pendant que vous utilisez Me montrer (pour vous placer près de votre arrêt et du bus ; elle reste sur votre téléphone, n\'est jamais envoyée ni conservée).',
      'Ce que fait le bus dans Mon bus (à un arrêt, à l\'arrêt, près de votre arrêt) : votre téléphone le calcule pendant que vous regardez, et rien n\'est conservé.',
      'Vos contacts, photos ou fichiers, en dehors de la preuve de paiement que vous choisissez d\'envoyer.',
      'Des profils publicitaires. Il n\'y a aucune publicité dans BusIn.',
    ]),
    LegalSection('Qui peut le voir', bullets: [
      'Vous voyez vos propres données.',
      'Les administrateurs et le personnel de votre école voient ce qui est nécessaire à leur rôle : les administrateurs vos informations, demandes et embarquements ; le personnel à la porte votre nom, votre photo, votre matricule et votre arrêt quand votre code est scanné.',
      'Pour que la porte fonctionne sans réseau, un téléphone du personnel garde, pour la journée seulement, la liste des voyageurs du jour avec ces mêmes informations et une clé valable ce jour-là. Elle est effacée à la déconnexion et remplacée le lendemain.',
      'Les autres étudiants ne voient rien de vous. Si vous activez les séries, les étudiants de votre école voient votre prénom, l\'initiale de votre nom, votre photo et votre série sur le tableau ; désactivez les séries pour le quitter.',
      'Aucune école ne voit les données d\'une autre.',
      'Nous ne vendons pas vos données et ne les partageons pas avec des annonceurs. Nous faisons appel à des prestataires pour faire fonctionner l\'application (hébergement, connexion, notifications, rapports de plantage), soumis au même devoir de précaution.',
      'Quand vous payez dans l\'application, pawaPay (une société de paiement) et votre opérateur mobile money (MTN ou Orange) reçoivent votre numéro et le montant pour traiter le paiement ou un remboursement, selon leurs propres conditions et la loi sur les paiements.',
    ]),
    LegalSection('Si vous êtes membre du personnel ou chauffeur', bullets: [
      'Les scans que vous faites sont enregistrés avec votre compte, l\'heure et l\'arrêt le plus proche.',
      'Quand vous partagez la position du bus pendant un trajet que vous conduisez, votre téléphone envoie sa position toutes les quelques secondes, avec une notification visible tout le temps. Les abonnés et les administrateurs de votre école voient le bus ; les administrateurs voient aussi une trace allégée du trajet, gardée pour estimer les arrivées.',
      'Le partage s\'arrête à la fin du trajet ou quand vous le coupez. La position de votre téléphone n\'est jamais lue en dehors d\'un trajet que vous conduisez.',
      'Votre école peut vous ajouter par e-mail, y compris avec une adresse personnelle. Le rôle qu\'elle vous donne est lié à ce compte.',
    ]),
    LegalSection('Comment elles sont protégées', bullets: [
      'Les règles d\'accès sont appliquées sur le serveur, pour chaque requête et chaque école.',
      'Le secret de votre code d\'embarquement est gardé dans le stockage sécurisé de votre téléphone et n\'est jamais affiché. La clé du jour d\'un téléphone du personnel ne permet pas de produire votre code pour un autre jour.',
      'Les preuves de paiement sont stockées de façon privée et ouvertes seulement par des liens de courte durée.',
      'Les connexions au service sont chiffrées.',
    ]),
    LegalSection('Combien de temps', paragraphs: [
      'Votre compte et votre historique sont conservés tant que vous êtes inscrit et utilisez le service, et aussi longtemps que votre école en a besoin pour ses registres ou que la loi l\'exige. Demandez à votre école combien de temps elle les garde. Les paiements, remboursements et reçus sont conservés 10 ans, comme l\'exige la loi comptable, y compris après la suppression de votre compte, sans votre nom.',
    ]),
    LegalSection('Vos choix', bullets: [
      'Corrigez vos informations dans le profil à tout moment.',
      'Désactivez les notifications dans les réglages de votre téléphone.',
      'Modifiez ou supprimez votre zone dans Ma zone à tout moment. La recherche de lieux se fait sur les serveurs de BusIn, sur une copie d\'OpenStreetMap : ce que vous tapez n\'est envoyé à personne d\'autre.',
      'Demandez à votre école une copie de vos données. Supprimez vous-même votre compte depuis votre profil, ou, si vous ne pouvez plus vous connecter, demandez-le depuis le site BusIn (Supprimer votre compte, en bas de la page d\'accueil) : vos nom, coordonnées, photo, matricule, zone de domicile et preuves de paiement sont effacés 7 jours plus tard, et votre école garde ses registres sans votre nom.',
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
      'Paying from a number that is not yours without its owner\'s agreement, or asking for a refund you are not owed.',
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
      'Payer depuis un numéro qui n\'est pas le vôtre sans l\'accord de son titulaire, ou demander un remboursement qui ne vous est pas dû.',
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

// The payments and refunds policy (ADR 0029): what paying in the app means, fees, refunds and problems.
const _paymentsEn = LegalDocument(
  highlights: [
    'Where your school offers it, you can pay your bus pass in the app with MTN Mobile Money or Orange Money, or keep paying the school and sending a receipt.',
    'You see the price, any fee and the total before you pay. A payment that does not go through takes nothing.',
    'Your school decides refunds. A payment BusIn cannot use is refunded in full, fee included.',
  ],
  sections: [
    LegalSection('Who you pay', paragraphs: [
      'BusIn collects mobile money payments for your school through pawaPay, a payment company, and your mobile money operator. The price is your school\'s, and BusIn passes the school\'s share on to it. Your school provides the bus service and remains responsible for it.',
    ]),
    LegalSection('Prices and fees', bullets: [
      'The price is set by your school. It may include BusIn\'s charge for the service when your school passes it on; then it is the same whichever way you pay.',
      'Paying by mobile money may add a fee that covers what moving the money costs (pawaPay\'s and the operator\'s charges). Whether it applies is your school\'s choice, and the app shows it before you pay.',
      'Amounts are in CFA francs (XAF), without decimals.',
    ]),
    LegalSection('Paying', bullets: [
      'You can pay from your own number, or from someone else\'s with their agreement.',
      'The app recognises your operator from the number; you can change it.',
      'Your phone shows a prompt from your operator: confirm with your PIN. The payment is complete only when your operator confirms it.',
      'If your connection drops, the payment is not lost: BusIn finishes it and tells you the result.',
      'If it does not go through, nothing is taken. You can try again, or send a receipt of a payment made to your school instead.',
    ]),
    LegalSection('When it goes through', paragraphs: [
      'Your request is approved, or the part is marked paid, at once, and you get a numbered receipt in the app. Your school sees the same receipt.',
    ]),
    LegalSection('Refunds', bullets: [
      'Ask from your receipt in the app, with a reason. Your school decides, may refund all or part of the price, and says why if it declines.',
      'The mobile money fee is not refunded, as it paid for the transfers, unless the mistake was BusIn\'s.',
      'If your payment cannot be used (for example the request was already paid, or its period has ended), BusIn refunds it in full, fee included, without you asking.',
      'A refund goes back to the number that paid. Refunding the whole price ends the subscription.',
      'If a refund cannot be sent, you are told and it is sent again.',
      'If you paid the school directly and sent a receipt, refunds are between you and your school.',
    ]),
    LegalSection('Problems', paragraphs: [
      'If money was taken but the app does not show the payment, tell your school with your operator\'s reference: every payment is checked against pawaPay\'s records. Please contact us before asking your operator to reverse a payment.',
      'Payments, refunds and receipts are kept for 10 years for accounting, also after your account is deleted, without your name.',
    ]),
    LegalSection('Changes', paragraphs: [
      'If fees or these rules change, the app tells you before they apply to you.',
    ]),
  ],
);

const _paymentsFr = LegalDocument(
  highlights: [
    'Si votre école le propose, vous pouvez payer votre pass de bus dans l\'application avec MTN Mobile Money ou Orange Money, ou continuer à payer l\'école et envoyer un reçu.',
    'Vous voyez le prix, les éventuels frais et le total avant de payer. Un paiement qui n\'aboutit pas ne prélève rien.',
    'Votre école décide des remboursements. Un paiement que BusIn ne peut pas utiliser est remboursé en entier, frais compris.',
  ],
  sections: [
    LegalSection('Qui vous payez', paragraphs: [
      'BusIn encaisse les paiements mobile money pour votre école par l\'intermédiaire de pawaPay, une société de paiement, et de votre opérateur mobile money. Le prix est celui de votre école, et BusIn lui reverse sa part. Votre école fournit le service de bus et en reste responsable.',
    ]),
    LegalSection('Prix et frais', bullets: [
      'Le prix est fixé par votre école. Il peut inclure les frais de service de BusIn quand votre école les répercute ; il est alors le même quelle que soit la façon de payer.',
      'Payer par mobile money peut ajouter des frais qui couvrent le coût du transfert (les frais de pawaPay et de l\'opérateur). Votre école décide s\'ils s\'appliquent, et l\'application les affiche avant le paiement.',
      'Les montants sont en francs CFA (XAF), sans décimales.',
    ]),
    LegalSection('Payer', bullets: [
      'Vous pouvez payer depuis votre numéro, ou depuis celui de quelqu\'un d\'autre avec son accord.',
      'L\'application reconnaît votre opérateur à partir du numéro ; vous pouvez le changer.',
      'Votre téléphone affiche une demande de votre opérateur : confirmez avec votre code. Le paiement n\'est terminé que lorsque votre opérateur le confirme.',
      'Si la connexion coupe, le paiement n\'est pas perdu : BusIn le termine et vous indique le résultat.',
      'S\'il n\'aboutit pas, rien n\'est prélevé. Vous pouvez réessayer, ou envoyer à la place le reçu d\'un paiement fait à votre école.',
    ]),
    LegalSection('Quand le paiement passe', paragraphs: [
      'Votre demande est approuvée, ou la tranche marquée payée, aussitôt, et vous recevez un reçu numéroté dans l\'application. Votre école voit le même reçu.',
    ]),
    LegalSection('Remboursements', bullets: [
      'Demandez-le depuis votre reçu dans l\'application, avec un motif. Votre école décide, peut rembourser tout ou partie du prix, et indique pourquoi si elle refuse.',
      'Les frais mobile money ne sont pas remboursés, car ils ont payé les transferts, sauf si l\'erreur vient de BusIn.',
      'Si votre paiement ne peut pas être utilisé (par exemple la demande était déjà payée, ou sa période est terminée), BusIn le rembourse en entier, frais compris, sans que vous le demandiez.',
      'Un remboursement revient au numéro qui a payé. Rembourser tout le prix met fin à l\'abonnement.',
      'Si un remboursement ne peut pas être envoyé, vous en êtes informé et il est renvoyé.',
      'Si vous avez payé l\'école directement et envoyé un reçu, les remboursements se règlent entre vous et votre école.',
    ]),
    LegalSection('En cas de problème', paragraphs: [
      'Si de l\'argent a été prélevé mais que l\'application n\'affiche pas le paiement, prévenez votre école avec la référence de votre opérateur : chaque paiement est vérifié dans les registres de pawaPay. Contactez-nous avant de demander à votre opérateur d\'annuler un paiement.',
      'Les paiements, remboursements et reçus sont conservés 10 ans pour la comptabilité, y compris après la suppression de votre compte, sans votre nom.',
    ]),
    LegalSection('Modifications', paragraphs: [
      'Si les frais ou ces règles changent, l\'application vous prévient avant qu\'ils ne s\'appliquent à vous.',
    ]),
  ],
);

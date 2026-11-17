import type { Locale } from "@/lib/i18n/messages";

/**
 * The terms a school accepts to use BusIn, shown on the school profile page. DRAFT: to be reviewed by the owner (and a
 * lawyer if needed) before schools are asked to accept them for real. The version is SCHOOL_TERMS_VERSION in lib/school.ts;
 * changing the meaning of these terms means a new version, which asks every school to accept again.
 */
export type SchoolTerms = { title: string; summary: string; sections: { title: string; body: string }[] };

const en: SchoolTerms = {
  title: "Terms for schools",
  summary: "What your school agrees to by using BusIn. In short: your data stays yours, your name and logo are shown publicly only if you choose to, and BusIn collects mobile money payments for you and pays them out every week.",
  sections: [
    {
      title: "Using BusIn",
      body: "BusIn helps your school run its student buses: subscriptions, passes, boarding and following the bus. Your school decides who rides, sets up stops, buses and semesters, and names the people who administer it.",
    },
    {
      title: "Your data and your students' data",
      body: "The information your school and your students put into BusIn belongs to your school. BusIn keeps it only to run the service, never sells it, and never mixes it with another school's. Students' phones are never tracked: a student who chooses to see themselves on the bus map keeps that position on their phone. A staff phone shares where the bus is only during a trip it runs, with a notification showing.",
    },
    {
      title: "Staff phones",
      body: "So passes can be checked without a signal, a staff phone keeps, for that day only, the list of the day's riders (name, photo, matricule, stop) and a key valid for that day; it is deleted at sign-out. Your school makes sure staff phones are locked, and if one is lost it suspends that account in People.",
    },
    {
      title: "Insights",
      body: "BusIn counts boardings per stop and departure and, from the areas students choose to share, how far they live from their stops. Only figures for groups of at least five students are shown, never a single student. The figures help your school plan; nothing about stops or routes changes by itself.",
    },
    {
      title: "Your name and logo",
      body: "By accepting these terms you allow BusIn to show your school's name, city and logo publicly, for example on the wall of schools on the BusIn website and in the student app, while \"Show our school publicly\" is on. You can turn it off at any time; the name and logo then leave public pages. You confirm your school has the right to use the logo it uploads.",
    },
    {
      title: "Administrators",
      body: "Your school gives administrator and staff access only to people who need it, including people it adds by email, and removes it when they leave. Whoever holds an invited email receives the role, so check addresses before adding them. Actions taken by your administrators are your school's responsibility, and each one is recorded in an audit log. Trips left running from an earlier day are ended automatically.",
    },
    {
      title: "Collecting payments for your school",
      body: "Where BusIn switches mobile money on for your school, students can pay in the app with MTN Mobile Money or Orange Money. BusIn collects these payments on your school's behalf through pawaPay, a payment company, and passes your school's share on to it. Each payment approves the request, or marks the part paid, at once. Your school sees every payment, receipt, refund and payout in Payments, and can download its ledger.",
    },
    {
      title: "Fees and BusIn's charge",
      body: "BusIn charges your school an amount for each paying student (each subscription approved, however it was paid), from the date agreed with your school. It is taken from your school's balance, or invoiced on the 1st of the month when the balance cannot cover it, due in 14 days. Your school chooses who pays the fees: its students (BusIn's charge in the price, and mobile money's transfer costs on top when they pay that way) or the school (both out of its share). Billing shows what students pay and what your school receives.",
    },
    {
      title: "Holding and paying out",
      body: "Money from a payment is held for 7 days, then paid out every Monday to the mobile money number your school registered, when it is above the minimum. A new number is confirmed by a second administrator, or by BusIn for a school with a single administrator, and a number that replaces another is used 7 days after it is confirmed. Your school keeps that number correct. A negative balance is what your school owes BusIn.",
    },
    {
      title: "Refunds",
      body: "Your school decides the refunds its students ask for: all or part of the price, or a refusal with a reason. It can also refund on its own. A refund is taken from your school's balance, with what sending it costs. BusIn refunds in full, at its own cost, a payment it could not apply. Your school tells its students its refund rules and follows them.",
    },
    {
      title: "Our payment provider's terms",
      body: "BusIn collects through pawaPay as an intermediary merchant, and your school is its sub-merchant. By accepting these terms, your school also accepts pawaPay's terms for sub-merchants, which pawaPay may enforce directly, including suspending payments for a school that breaks them. Your school only sells lawful services through BusIn, does not charge students more for paying by mobile money than these terms allow, keeps its payment records for 10 years, and answers BusIn's questions about a disputed payment within one business day.",
    },
    {
      title: "Changes",
      body: "If these terms change in a way that matters, BusIn will ask your school to accept the new version. Until then, the version you accepted applies.",
    },
  ],
};

const fr: SchoolTerms = {
  title: "Conditions pour les écoles",
  summary: "Ce que votre école accepte en utilisant BusIn. En bref : vos données restent les vôtres, votre nom et votre logo ne sont publics que si vous le choisissez, et BusIn encaisse pour vous les paiements mobile money et vous les verse chaque semaine.",
  sections: [
    {
      title: "Utiliser BusIn",
      body: "BusIn aide votre école à gérer ses bus étudiants : abonnements, pass, montées et suivi du bus. Votre école décide qui voyage, configure les arrêts, les bus et les semestres, et désigne les personnes qui l'administrent.",
    },
    {
      title: "Vos données et celles de vos étudiants",
      body: "Les informations que votre école et vos étudiants saisissent dans BusIn appartiennent à votre école. BusIn ne les garde que pour faire fonctionner le service, ne les vend jamais et ne les mélange jamais avec celles d'une autre école. Les téléphones des étudiants ne sont jamais suivis : un étudiant qui choisit de se voir sur la carte du bus garde cette position sur son téléphone. Un téléphone du personnel ne partage la position du bus que pendant un trajet qu'il conduit, avec une notification visible.",
    },
    {
      title: "Téléphones du personnel",
      body: "Pour vérifier les pass sans réseau, un téléphone du personnel garde, pour la journée seulement, la liste des voyageurs du jour (nom, photo, matricule, arrêt) et une clé valable ce jour-là ; elle est effacée à la déconnexion. Votre école veille à ce que ces téléphones soient verrouillés et, en cas de perte, suspend le compte concerné dans Personnes.",
    },
    {
      title: "Analyses",
      body: "BusIn compte les montées par arrêt et par départ et, à partir des zones que les étudiants choisissent de partager, leur distance aux arrêts. Seuls des chiffres portant sur au moins cinq étudiants sont affichés, jamais un étudiant seul. Ils aident votre école à planifier ; rien ne change de soi-même dans les arrêts ou les trajets.",
    },
    {
      title: "Votre nom et votre logo",
      body: "En acceptant ces conditions, vous autorisez BusIn à afficher publiquement le nom, la ville et le logo de votre école, par exemple sur le mur des écoles du site BusIn et dans l'application étudiante, tant que « Afficher notre école publiquement » est activé. Vous pouvez le désactiver à tout moment ; le nom et le logo quittent alors les pages publiques. Vous confirmez que votre école a le droit d'utiliser le logo qu'elle envoie.",
    },
    {
      title: "Administrateurs",
      body: "Votre école ne donne l'accès administrateur et personnel qu'aux personnes qui en ont besoin, y compris celles qu'elle ajoute par e-mail, et le retire quand elles partent. La personne qui détient un e-mail invité reçoit le rôle : vérifiez les adresses avant de les ajouter. Les actions de vos administrateurs relèvent de votre école, et chacune est enregistrée dans un journal. Les trajets restés en cours depuis un jour précédent sont terminés automatiquement.",
    },
    {
      title: "Encaisser les paiements pour votre école",
      body: "Si BusIn active le mobile money pour votre école, les étudiants peuvent payer dans l'application avec MTN Mobile Money ou Orange Money. BusIn encaisse ces paiements pour le compte de votre école par l'intermédiaire de pawaPay, une société de paiement, et reverse à votre école sa part. Chaque paiement approuve la demande, ou marque la tranche payée, aussitôt. Votre école voit chaque paiement, reçu, remboursement et virement dans Paiements, et peut télécharger son grand livre.",
    },
    {
      title: "Frais et frais de service de BusIn",
      body: "BusIn facture à votre école un montant par étudiant payant (chaque abonnement approuvé, quel que soit le mode de paiement), à partir de la date convenue avec votre école. Il est prélevé sur le solde de votre école, ou facturé le 1er du mois quand le solde ne suffit pas, payable sous 14 jours. Votre école choisit qui paie les frais : ses étudiants (les frais de BusIn dans le prix, et le coût du transfert mobile money en plus quand ils paient ainsi) ou l'école (les deux pris sur sa part). Facturation montre ce que paient les étudiants et ce que reçoit votre école.",
    },
    {
      title: "Attente et versements",
      body: "L'argent d'un paiement est gardé 7 jours, puis versé chaque lundi sur le numéro mobile money enregistré par votre école, au-dessus du minimum. Un nouveau numéro est confirmé par un second administrateur, ou par BusIn pour une école qui n'a qu'un administrateur, et un numéro qui en remplace un autre est utilisé 7 jours après sa confirmation. Votre école tient ce numéro à jour. Un solde négatif est ce que votre école doit à BusIn.",
    },
    {
      title: "Remboursements",
      body: "Votre école décide des remboursements que ses étudiants demandent : tout ou partie du prix, ou un refus motivé. Elle peut aussi rembourser d'elle-même. Un remboursement est pris sur le solde de votre école, avec le coût de son envoi. BusIn rembourse en entier, à ses frais, un paiement qu'il n'a pas pu appliquer. Votre école communique ses règles de remboursement à ses étudiants et les respecte.",
    },
    {
      title: "Les conditions de notre prestataire de paiement",
      body: "BusIn encaisse par l'intermédiaire de pawaPay en tant que marchand intermédiaire, et votre école en est le sous-marchand. En acceptant ces conditions, votre école accepte aussi les conditions de pawaPay pour les sous-marchands, que pawaPay peut faire appliquer directement, y compris en suspendant les paiements d'une école qui ne les respecte pas. Votre école ne vend par BusIn que des services licites, ne fait pas payer aux étudiants plus que ces conditions ne le permettent pour un paiement par mobile money, conserve ses justificatifs de paiement 10 ans et répond sous un jour ouvré aux questions de BusIn sur un paiement contesté.",
    },
    {
      title: "Modifications",
      body: "Si ces conditions changent de façon importante, BusIn demandera à votre école d'accepter la nouvelle version. D'ici là, la version acceptée s'applique.",
    },
  ],
};

export const schoolTerms: Record<Locale, SchoolTerms> = { en, fr };

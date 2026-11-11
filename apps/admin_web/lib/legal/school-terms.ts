import type { Locale } from "@/lib/i18n/messages";

/**
 * The terms a school accepts to use BusIn, shown on the school profile page. DRAFT: to be reviewed by the owner (and a
 * lawyer if needed) before schools are asked to accept them for real. The version is SCHOOL_TERMS_VERSION in lib/school.ts;
 * changing the meaning of these terms means a new version, which asks every school to accept again.
 */
export type SchoolTerms = { title: string; summary: string; sections: { title: string; body: string }[] };

const en: SchoolTerms = {
  title: "Terms for schools",
  summary: "What your school agrees to by using BusIn. In short: your data stays yours, and your name and logo are shown publicly only if you choose to.",
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
      title: "Changes",
      body: "If these terms change in a way that matters, BusIn will ask your school to accept the new version. Until then, the version you accepted applies.",
    },
  ],
};

const fr: SchoolTerms = {
  title: "Conditions pour les écoles",
  summary: "Ce que votre école accepte en utilisant BusIn. En bref : vos données restent les vôtres, et votre nom et votre logo ne sont publics que si vous le choisissez.",
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
      title: "Modifications",
      body: "Si ces conditions changent de façon importante, BusIn demandera à votre école d'accepter la nouvelle version. D'ici là, la version acceptée s'applique.",
    },
  ],
};

export const schoolTerms: Record<Locale, SchoolTerms> = { en, fr };

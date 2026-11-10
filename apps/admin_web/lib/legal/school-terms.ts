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
      body: "The information your school and your students put into BusIn belongs to your school. BusIn keeps it only to run the service, never sells it, and never mixes it with another school's. Students' phones are never tracked; only a bus shares where it is, during a trip.",
    },
    {
      title: "Your name and logo",
      body: "By accepting these terms you allow BusIn to show your school's name, city and logo publicly, for example on the wall of schools on the BusIn website and in the student app, while \"Show our school publicly\" is on. You can turn it off at any time; the name and logo then leave public pages. You confirm your school has the right to use the logo it uploads.",
    },
    {
      title: "Administrators",
      body: "Your school gives administrator access only to people who need it and removes it when they leave. Actions taken by your administrators are your school's responsibility, and each one is recorded in an audit log.",
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
      body: "Les informations que votre école et vos étudiants saisissent dans BusIn appartiennent à votre école. BusIn ne les garde que pour faire fonctionner le service, ne les vend jamais et ne les mélange jamais avec celles d'une autre école. Les téléphones des étudiants ne sont jamais suivis ; seul un bus partage sa position, pendant un trajet.",
    },
    {
      title: "Votre nom et votre logo",
      body: "En acceptant ces conditions, vous autorisez BusIn à afficher publiquement le nom, la ville et le logo de votre école, par exemple sur le mur des écoles du site BusIn et dans l'application étudiante, tant que « Afficher notre école publiquement » est activé. Vous pouvez le désactiver à tout moment ; le nom et le logo quittent alors les pages publiques. Vous confirmez que votre école a le droit d'utiliser le logo qu'elle envoie.",
    },
    {
      title: "Administrateurs",
      body: "Votre école ne donne l'accès administrateur qu'aux personnes qui en ont besoin, et le retire quand elles partent. Les actions de vos administrateurs relèvent de votre école, et chacune est enregistrée dans un journal.",
    },
    {
      title: "Modifications",
      body: "Si ces conditions changent de façon importante, BusIn demandera à votre école d'accepter la nouvelle version. D'ici là, la version acceptée s'applique.",
    },
  ],
};

export const schoolTerms: Record<Locale, SchoolTerms> = { en, fr };

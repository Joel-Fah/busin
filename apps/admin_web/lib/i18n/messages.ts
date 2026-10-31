/**
 * All user-facing text. English is the reference; French must have exactly the same shape,
 * so a missing translation fails the type check.
 */
export const en = {
  appName: 'BusIn',
  language: { label: 'Language', en: 'English', fr: 'Français' },
  login: {
    title: 'Sign in to the admin portal',
    hint: 'Use your school Google account. Only administrators can enter.',
    button: 'Continue with Google',
    errors: {
      auth_failed: 'Sign-in did not complete. Try again.',
      domain_not_allowed: 'This account could not be created. The email domain may not be enabled for BusIn.',
      generic: 'Something went wrong while signing in. Try again.',
    },
  },
  noAccess: {
    title: 'No access',
    body: 'This portal is for school administrators. Your account does not have that role.',
    signedInAs: 'Signed in as {email}',
    signOut: 'Sign out',
  },
  nav: {
    overview: 'Overview',
    subscriptions: 'Subscriptions',
    signOut: 'Sign out',
    primary: 'Main navigation',
  },
  overview: {
    title: 'Overview',
    subtitle: 'What needs attention at {school} today.',
    pendingSubscriptions: 'Subscriptions to review',
    students: 'Students',
    activeTrips: 'Trips running now',
    scansToday: 'Boardings today',
    loadError: 'The figures could not be loaded. Reload the page to try again.',
  },
  status: {
    pending: 'Pending',
    approved: 'Approved',
    rejected: 'Rejected',
    expired: 'Expired',
  },
  semester: { fall: 'Fall', spring: 'Spring', summer: 'Summer' },
  subscriptions: {
    title: 'Subscriptions',
    subtitle: 'Review payment proofs and decide who may board.',
    filtersLabel: 'Filter by status',
    filters: {
      pending: 'To review',
      approved: 'Approved',
      rejected: 'Rejected',
      expired: 'Expired',
      all: 'All',
    },
    columns: {
      student: 'Student',
      semester: 'Semester',
      stop: 'Stop',
      submitted: 'Submitted',
      status: 'Status',
    },
    empty: 'No subscriptions match this filter.',
    loadError: 'The subscriptions could not be loaded. Reload the page to try again.',
    paginationLabel: 'Pages',
    range: 'Showing {from} to {to} of {total}',
    previous: 'Previous',
    next: 'Next',
    detail: {
      back: 'Back to subscriptions',
      student: 'Student',
      email: 'Email',
      matricule: 'Matricule',
      semester: 'Semester',
      stop: 'Stop',
      submitted: 'Submitted',
      status: 'Status',
      proof: 'Payment proof',
      proofImageAlt: 'Payment proof uploaded by the student',
      proofOpen: 'Open proof in a new tab',
      proofMissing: 'No proof was uploaded.',
      proofUnavailable: 'The proof could not be loaded. Reload the page to try again.',
      decision: 'Decision',
      reviewedBy: 'Reviewed by {name} on {date}',
      note: 'Note to the student',
      approve: 'Approve',
      approveHint: 'The student can board for the whole semester.',
      rejectOpen: 'Reject with a reason',
      reasonLabel: 'Reason for rejection',
      reasonHint: 'The student will see this. 500 characters at most.',
      rejectConfirm: 'Confirm rejection',
    },
    done: {
      approved: 'Subscription approved.',
      rejected: 'Subscription rejected.',
    },
    errors: {
      already_reviewed: 'This subscription was already reviewed.',
      invalid: 'Check the reason (required, 500 characters at most) and try again.',
      not_found: 'Subscription not found.',
      generic: 'The decision could not be saved. Try again.',
    },
  },
  notFound: {
    title: 'Page not found',
    body: 'This page does not exist or you cannot see it.',
    back: 'Back to the overview',
  },
} as const;

type Widen<T> = T extends string
  ? string
  : { -readonly [K in keyof T]: Widen<T[K]> };

export type Messages = Widen<typeof en>;

export const fr: Messages = {
  appName: 'BusIn',
  language: { label: 'Langue', en: 'English', fr: 'Français' },
  login: {
    title: 'Connexion au portail administrateur',
    hint: 'Utilisez votre compte Google scolaire. Seuls les administrateurs peuvent entrer.',
    button: 'Continuer avec Google',
    errors: {
      auth_failed: "La connexion n'a pas abouti. Réessayez.",
      domain_not_allowed: "Ce compte n'a pas pu être créé. Le domaine de l'email n'est peut-être pas activé pour BusIn.",
      generic: 'Un problème est survenu pendant la connexion. Réessayez.',
    },
  },
  noAccess: {
    title: 'Accès refusé',
    body: "Ce portail est réservé aux administrateurs de l'école. Votre compte n'a pas ce rôle.",
    signedInAs: 'Connecté en tant que {email}',
    signOut: 'Se déconnecter',
  },
  nav: {
    overview: "Vue d'ensemble",
    subscriptions: 'Abonnements',
    signOut: 'Se déconnecter',
    primary: 'Navigation principale',
  },
  overview: {
    title: "Vue d'ensemble",
    subtitle: "Ce qui demande de l'attention à {school} aujourd'hui.",
    pendingSubscriptions: 'Abonnements à examiner',
    students: 'Étudiants',
    activeTrips: 'Trajets en cours',
    scansToday: "Embarquements aujourd'hui",
    loadError: "Les chiffres n'ont pas pu être chargés. Rechargez la page pour réessayer.",
  },
  status: {
    pending: 'En attente',
    approved: 'Approuvé',
    rejected: 'Refusé',
    expired: 'Expiré',
  },
  semester: { fall: 'Automne', spring: 'Printemps', summer: 'Été' },
  subscriptions: {
    title: 'Abonnements',
    subtitle: 'Examinez les preuves de paiement et décidez qui peut embarquer.',
    filtersLabel: 'Filtrer par statut',
    filters: {
      pending: 'À examiner',
      approved: 'Approuvés',
      rejected: 'Refusés',
      expired: 'Expirés',
      all: 'Tous',
    },
    columns: {
      student: 'Étudiant',
      semester: 'Semestre',
      stop: 'Arrêt',
      submitted: 'Envoyé',
      status: 'Statut',
    },
    empty: 'Aucun abonnement ne correspond à ce filtre.',
    loadError: "Les abonnements n'ont pas pu être chargés. Rechargez la page pour réessayer.",
    paginationLabel: 'Pages',
    range: 'Affichage de {from} à {to} sur {total}',
    previous: 'Précédent',
    next: 'Suivant',
    detail: {
      back: 'Retour aux abonnements',
      student: 'Étudiant',
      email: 'Email',
      matricule: 'Matricule',
      semester: 'Semestre',
      stop: 'Arrêt',
      submitted: 'Envoyé',
      status: 'Statut',
      proof: 'Preuve de paiement',
      proofImageAlt: "Preuve de paiement envoyée par l'étudiant",
      proofOpen: 'Ouvrir la preuve dans un nouvel onglet',
      proofMissing: "Aucune preuve n'a été envoyée.",
      proofUnavailable: "La preuve n'a pas pu être chargée. Rechargez la page pour réessayer.",
      decision: 'Décision',
      reviewedBy: 'Examiné par {name} le {date}',
      note: "Message à l'étudiant",
      approve: 'Approuver',
      approveHint: "L'étudiant peut embarquer pour tout le semestre.",
      rejectOpen: 'Refuser avec un motif',
      reasonLabel: 'Motif du refus',
      reasonHint: "L'étudiant le verra. 500 caractères au maximum.",
      rejectConfirm: 'Confirmer le refus',
    },
    done: {
      approved: 'Abonnement approuvé.',
      rejected: 'Abonnement refusé.',
    },
    errors: {
      already_reviewed: 'Cet abonnement a déjà été examiné.',
      invalid: 'Vérifiez le motif (obligatoire, 500 caractères au maximum) et réessayez.',
      not_found: 'Abonnement introuvable.',
      generic: "La décision n'a pas pu être enregistrée. Réessayez.",
    },
  },
  notFound: {
    title: 'Page introuvable',
    body: "Cette page n'existe pas ou vous ne pouvez pas la voir.",
    back: "Retour à la vue d'ensemble",
  },
};

export type Locale = 'en' | 'fr';
export const locales: readonly Locale[] = ['en', 'fr'];
export const defaultLocale: Locale = 'en';

export const catalogues: Record<Locale, Messages> = { en, fr };

export function isLocale(value: string | undefined | null): value is Locale {
  return value === 'en' || value === 'fr';
}

/** Replaces `{name}` placeholders. Unknown placeholders are left as they are. */
export function format(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (match, key: string) =>
    key in values ? String(values[key]) : match,
  );
}

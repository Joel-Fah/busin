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
  devLogin: {
    title: 'Local development sign-in',
    warning: 'Development only. This page does not exist in a production build.',
    hint: 'Use an account made with "npm run dev:user". Google sign-in is the real way in.',
    email: 'Email',
    password: 'Password',
    button: 'Sign in',
    error: 'Wrong email or password, or this account does not exist on this machine.',
    link: 'Local development sign-in',
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
  devLogin: {
    title: 'Connexion locale de développement',
    warning: "Développement uniquement. Cette page n'existe pas dans une version de production.",
    hint: "Utilisez un compte créé avec « npm run dev:user ». La connexion Google est la vraie voie d'accès.",
    email: 'Email',
    password: 'Mot de passe',
    button: 'Se connecter',
    error: "Email ou mot de passe incorrect, ou ce compte n'existe pas sur cette machine.",
    link: 'Connexion locale de développement',
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

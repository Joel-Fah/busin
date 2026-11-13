import type { Locale } from "@/lib/i18n/messages";

/**
 * The words of the student web app (ADR 0021), in both languages. They are the student app's own words, copied from the
 * shared ARB files (packages/busin_ui/lib/src/l10n), so a student reads the same thing on the phone and in the browser:
 * change both together. Words only the web needs (installing, the browser's permissions) are written in the same voice.
 * Kept apart from the portal's catalogue so the portal never ships them and students never download the portal's.
 * Both languages have the same keys; a test checks it.
 */
const en = {
  meta: { title: "BusIn", description: "Subscribe to the school bus, show your boarding code and follow your bus." },
  nav: {
    label: "BusIn",
    subscription: "Subscription",
    code: "Code",
    codeFull: "Boarding code",
    bus: "My bus",
    profile: "Profile",
  },
  signIn: {
    title: "Hop on. BusIn handles the rest.",
    subtitle: "Sign in with your school Google account to subscribe, show your boarding code and follow your bus.",
    button: "Continue with Google",
    cancelled: "Sign-in was cancelled.",
    failed: "Sign-in did not work. Try again.",
    notAllowed: "This Google account is not allowed here. Use your school account.",
    working: "Signing you in",
  },
  blocked: {
    staffTitle: "This app is for students",
    staffBody: "Your account is a staff or administrator account. Staff use the BusIn ops app, and administrators use the admin portal.",
    suspendedTitle: "Your account is suspended",
    suspendedBody: "Contact your school's transport office to find out why.",
    portal: "Open the admin portal",
  },
  profile: {
    title: "Your profile",
    signOut: "Sign out",
    appearance: "Appearance",
    appearanceHint: "Kept in this browser.",
    theme: "Theme",
    language: "Language",
    themes: { system: "System", light: "Light", dark: "Dark" },
  },
  install: {
    title: "Add BusIn to your home screen",
    body: "It opens like an app, works without a connection and can tell you when your bus is close.",
    button: "Install",
    iosBody: "In Safari, tap Share, then Add to Home Screen. You need this to get notifications on an iPhone.",
    dismiss: "Not now",
  },
  offline: {
    title: "No connection",
    body: "This page needs the internet. Your saved pass and boarding code still open from the app once it has been opened online.",
    retry: "Try again",
  },
  soon: { title: "Coming soon", body: "This part of BusIn is on its way to the web." },
  loading: "Loading",
};

export type StudentCopy = typeof en;

const fr: StudentCopy = {
  meta: { title: "BusIn", description: "Abonnez-vous au bus de l’école, présentez votre code d’embarquement et suivez votre bus." },
  nav: {
    label: "BusIn",
    subscription: "Abonnement",
    code: "Code",
    codeFull: "Code d’embarquement",
    bus: "Mon bus",
    profile: "Profil",
  },
  signIn: {
    title: "Montez à bord. BusIn s’occupe du reste.",
    subtitle: "Connectez-vous avec votre compte Google de l’école pour vous abonner, présenter votre code d’embarquement et suivre votre bus.",
    button: "Continuer avec Google",
    cancelled: "La connexion a été annulée.",
    failed: "La connexion n’a pas fonctionné. Réessayez.",
    notAllowed: "Ce compte Google n’est pas autorisé ici. Utilisez votre compte de l’école.",
    working: "Connexion en cours",
  },
  blocked: {
    staffTitle: "Cette application est réservée aux étudiants",
    staffBody: "Votre compte est un compte de personnel ou d’administrateur. Le personnel utilise l’application BusIn Ops et les administrateurs le portail d’administration.",
    suspendedTitle: "Votre compte est suspendu",
    suspendedBody: "Contactez le service transport de votre école pour en connaître la raison.",
    portal: "Ouvrir le portail d’administration",
  },
  profile: {
    title: "Votre profil",
    signOut: "Se déconnecter",
    appearance: "Apparence",
    appearanceHint: "Gardé dans ce navigateur.",
    theme: "Thème",
    language: "Langue",
    themes: { system: "Système", light: "Clair", dark: "Sombre" },
  },
  install: {
    title: "Ajoutez BusIn à votre écran d’accueil",
    body: "Il s’ouvre comme une application, fonctionne sans connexion et peut vous prévenir quand votre bus approche.",
    button: "Installer",
    iosBody: "Dans Safari, touchez Partager, puis Sur l’écran d’accueil. C’est nécessaire pour recevoir des notifications sur iPhone.",
    dismiss: "Plus tard",
  },
  offline: {
    title: "Pas de connexion",
    body: "Cette page a besoin d’internet. Votre abonnement et votre code d’embarquement s’ouvrent quand même dans l’application, une fois ouverte en ligne.",
    retry: "Réessayer",
  },
  soon: { title: "Bientôt", body: "Cette partie de BusIn arrive bientôt sur le web." },
  loading: "Chargement",
};

export const studentCatalogues: Record<Locale, StudentCopy> = { en, fr };

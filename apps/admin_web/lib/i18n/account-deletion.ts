/**
 * Account deletion copy (ADR 0028), shared by the admin portal, the student web app and the public page, in English and
 * French. Kept apart from the three catalogues so the same promises are worded once.
 */

const en = {
  card: {
    title: 'Delete my account',
    body: 'Your account and what identifies you are erased 7 days after you ask. You can cancel until then.',
    open: 'Delete my account',
    scheduled: 'Your account will be deleted on {date}.',
    scheduledByPlatform: 'BusIn scheduled the deletion of your account for {date}, as you asked.',
    cancel: 'Keep my account',
  },
  confirm: {
    title: 'Delete your account?',
    intro: 'In 7 days, BusIn erases:',
    erased: ['Your name, email, phone and photo', 'Your matricule and your home area', 'Your payment proofs and receipts', 'Your devices and notification settings'],
    kept: 'Your school keeps its records without your name: your subscriptions and payments, your boardings, the trips you drove.',
    subscription: 'Your pass stops working when your account is erased. Any refund is up to your school.',
    signInAgain: 'You can sign in again with the same Google account later: it starts as a new account.',
    cancelHint: 'Changed your mind? Cancel any time in the next 7 days from this page.',
    keep: 'Keep my account',
    delete: 'Delete in 7 days',
  },
  done: {
    requested: 'Your account will be deleted in 7 days.',
    cancelled: 'Deletion cancelled. Your account stays.',
  },
  errors: {
    last_admin: 'You are the last administrator of your school. Make someone else an administrator first, in People.',
    active_trip: 'You are on a running trip. End it first, then ask again.',
    generic: 'That did not work. Try again.',
  },
  page: {
    meta: 'How to delete your BusIn account, and what happens to your data.',
    title: 'Delete your BusIn account',
    intro: 'You can delete your account yourself, from the app or the website, at any time.',
    stepsTitle: 'How',
    steps: [
      'Open BusIn (the student app, the staff app, the website at /app, or the school portal) and sign in.',
      'Go to Profile, then Delete my account, and confirm.',
      'Your account is erased 7 days later. Until then you can cancel from the same place.',
    ],
    erasedTitle: 'What is erased',
    keptTitle: 'What your school keeps',
    lostTitle: 'You cannot sign in any more?',
    lostBody:
      'Send us the email of your BusIn account. We reply to that address to confirm it is yours, then schedule the deletion: it happens 7 days later.',
    email: 'Email of your account',
    message: 'Anything we should know (optional)',
    send: 'Ask for the deletion',
    sent: 'Received. We will write to that address to confirm.',
    already: 'You already asked, and we have it.',
    invalid: 'Check the email address.',
    busy: 'Too many requests just now. Try again in an hour.',
    failed: 'That did not work. Try again.',
    back: 'Back to BusIn',
  },
};

type Widen<T> = T extends string ? string : T extends readonly (infer U)[] ? Widen<U>[] : { -readonly [K in keyof T]: Widen<T[K]> };
export type DeletionCopy = Widen<typeof en>;

const fr: DeletionCopy = {
  card: {
    title: 'Supprimer mon compte',
    body: "Votre compte et ce qui vous identifie sont effacés 7 jours après votre demande. Vous pouvez annuler jusque-là.",
    open: 'Supprimer mon compte',
    scheduled: 'Votre compte sera supprimé le {date}.',
    scheduledByPlatform: 'BusIn a programmé la suppression de votre compte pour le {date}, comme vous l\'avez demandé.',
    cancel: 'Garder mon compte',
  },
  confirm: {
    title: 'Supprimer votre compte ?',
    intro: 'Dans 7 jours, BusIn efface :',
    erased: ['Votre nom, email, téléphone et photo', 'Votre matricule et votre zone de domicile', 'Vos preuves de paiement et reçus', 'Vos appareils et réglages de notifications'],
    kept: "Votre école garde ses registres sans votre nom : vos abonnements et paiements, vos embarquements, les trajets que vous avez conduits.",
    subscription: "Votre pass cesse de fonctionner quand votre compte est effacé. Un éventuel remboursement dépend de votre école.",
    signInAgain: 'Vous pourrez vous reconnecter plus tard avec le même compte Google : ce sera un nouveau compte.',
    cancelHint: "Vous changez d'avis ? Annulez à tout moment dans les 7 jours depuis cette page.",
    keep: 'Garder mon compte',
    delete: 'Supprimer dans 7 jours',
  },
  done: {
    requested: 'Votre compte sera supprimé dans 7 jours.',
    cancelled: 'Suppression annulée. Votre compte reste.',
  },
  errors: {
    last_admin: "Vous êtes le dernier administrateur de votre école. Nommez d'abord quelqu'un d'autre administrateur, dans Personnes.",
    active_trip: 'Vous êtes sur un trajet en cours. Terminez-le, puis redemandez.',
    generic: "Cela n'a pas fonctionné. Réessayez.",
  },
  page: {
    meta: 'Comment supprimer votre compte BusIn, et ce que deviennent vos données.',
    title: 'Supprimer votre compte BusIn',
    intro: "Vous pouvez supprimer votre compte vous-même, depuis l'application ou le site, à tout moment.",
    stepsTitle: 'Comment',
    steps: [
      "Ouvrez BusIn (l'application étudiante, l'application du personnel, le site à /app ou le portail de l'école) et connectez-vous.",
      'Allez dans Profil, puis Supprimer mon compte, et confirmez.',
      "Votre compte est effacé 7 jours plus tard. D'ici là, vous pouvez annuler au même endroit.",
    ],
    erasedTitle: 'Ce qui est effacé',
    keptTitle: 'Ce que garde votre école',
    lostTitle: 'Vous ne pouvez plus vous connecter ?',
    lostBody:
      "Envoyez-nous l'email de votre compte BusIn. Nous écrivons à cette adresse pour confirmer qu'elle est à vous, puis nous programmons la suppression : elle a lieu 7 jours plus tard.",
    email: 'Email de votre compte',
    message: 'Ce que nous devrions savoir (facultatif)',
    send: 'Demander la suppression',
    sent: 'Reçu. Nous écrirons à cette adresse pour confirmer.',
    already: 'Vous avez déjà demandé, et nous l\'avons.',
    invalid: "Vérifiez l'adresse email.",
    busy: 'Trop de demandes en ce moment. Réessayez dans une heure.',
    failed: "Cela n'a pas fonctionné. Réessayez.",
    back: 'Retour à BusIn',
  },
};

export const deletionCatalogues = { en: en as DeletionCopy, fr };

import type { Locale } from "@/lib/i18n/messages";

/**
 * The words of the public landing page, in both languages. Kept apart from the admin portal's catalogue: different voice
 * (warm and short), different audience, and the portal must not carry them. Both languages have the same keys; a test checks it.
 */
export type LandingCopy = {
  meta: { title: string; description: string; shareTitle: string };
  nav: { label: string; menu: string; day: string; people: string; schools: string; faq: string; cta: string };
  hero: { line1: string; marked: string; sub: string; note: string; chips: [string, string, string, string] };
  sections: Record<"day" | "people" | "private" | "download" | "schools" | "faq", { eyebrow: string; title: string; sub: string }>;
  footer: { tagline: string; staff: string; theme: string; rights: string };
};

const en: LandingCopy = {
  meta: {
    title: "BusIn: your campus ride, handled",
    description:
      "BusIn is the companion that rides along: subscribe once, show a code, watch the bus come. No queues, no guessing, no arguments at the door.",
    shareTitle: "BusIn: your bus, on time, on your side",
  },
  nav: { label: "Main", menu: "Menu", day: "A day with BusIn", people: "Who it helps", schools: "For schools", faq: "Questions", cta: "Get the app" },
  hero: {
    line1: "Your bus. On time.",
    marked: "On your side.",
    sub: "BusIn is the companion that rides along. Subscribe once, show a code, watch the bus come. No queues, no guessing, no arguments at the door.",
    note: "Free for students. Your school sets it up.",
    chips: ["Your bus is 4 min away", "Approved for this semester", "Your pass works offline", "Next bus at 7:40"],
  },
  sections: {
    day: { eyebrow: "A day with BusIn", title: "From 6:40 to the last bell", sub: "Follow one student through a morning that used to be stressful." },
    people: { eyebrow: "Who it helps", title: "Everyone's day gets easier", sub: "Students, drivers, the people at the door, and the school office." },
    private: { eyebrow: "Yours, and private", title: "Calm by design", sub: "Your school decides who rides. Nobody tracks your phone. It works when the signal does not." },
    download: { eyebrow: "Get BusIn", title: "Take it with you", sub: "The student app for your phone. Staff apps come from your school's admin." },
    schools: { eyebrow: "Schools that chose better", title: "A growing wall of schools that picked quality", sub: "Join the movement of schools that choose innovation for their students." },
    faq: { eyebrow: "Questions", title: "Good to know", sub: "Short answers to what people ask first." },
  },
  footer: { tagline: "A companion for the daily ride.", staff: "Staff sign in", theme: "Theme", rights: "BusIn" },
};

const fr: LandingCopy = {
  meta: {
    title: "BusIn : votre trajet au campus, simplifié",
    description:
      "BusIn est le compagnon qui voyage avec vous : abonnez-vous une fois, montrez un code, regardez le bus arriver. Plus de files, plus d'incertitude, plus de discussions à la porte.",
    shareTitle: "BusIn : votre bus, à l'heure, de votre côté",
  },
  nav: { label: "Principale", menu: "Menu", day: "Une journée avec BusIn", people: "Qui ça aide", schools: "Pour les écoles", faq: "Questions", cta: "Obtenir l'application" },
  hero: {
    line1: "Votre bus. À l'heure.",
    marked: "De votre côté.",
    sub: "BusIn est le compagnon qui voyage avec vous. Abonnez-vous une fois, montrez un code, regardez le bus arriver. Plus de files, plus d'incertitude, plus de discussions à la porte.",
    note: "Gratuit pour les étudiants. Votre école s'occupe de la mise en place.",
    chips: ["Votre bus arrive dans 4 min", "Approuvé pour ce semestre", "Votre pass marche hors connexion", "Prochain bus à 7 h 40"],
  },
  sections: {
    day: { eyebrow: "Une journée avec BusIn", title: "De 6 h 40 à la dernière sonnerie", sub: "Suivez un étudiant dans un matin qui était stressant." },
    people: { eyebrow: "Qui ça aide", title: "La journée de chacun devient plus simple", sub: "Étudiants, chauffeurs, personnel à la porte et bureau de l'école." },
    private: { eyebrow: "À vous, et privé", title: "Serein par conception", sub: "Votre école décide qui voyage. Personne ne suit votre téléphone. Ça marche même sans réseau." },
    download: { eyebrow: "Obtenir BusIn", title: "Emportez-le avec vous", sub: "L'application étudiante pour votre téléphone. Les applications du personnel viennent de l'administration de votre école." },
    schools: { eyebrow: "Les écoles qui ont choisi mieux", title: "Un mur d'écoles qui grandit, celles qui ont choisi la qualité", sub: "Rejoignez le mouvement des écoles qui choisissent l'innovation pour leurs étudiants." },
    faq: { eyebrow: "Questions", title: "Bon à savoir", sub: "Des réponses courtes à ce qu'on demande en premier." },
  },
  footer: { tagline: "Un compagnon pour le trajet de tous les jours.", staff: "Connexion du personnel", theme: "Thème", rights: "BusIn" },
};

export const landingCatalogues: Record<Locale, LandingCopy> = { en, fr };

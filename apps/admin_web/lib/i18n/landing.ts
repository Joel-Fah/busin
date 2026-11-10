import type { Locale } from "@/lib/i18n/messages";

/**
 * The words of the public landing page, in both languages. Kept apart from the admin portal's catalogue: different voice
 * (warm and short), different audience, and the portal must not carry them. Both languages have the same keys; a test checks it.
 */
export type LandingCopy = {
  meta: { title: string; description: string; shareTitle: string };
  nav: { label: string; menu: string; day: string; people: string; schools: string; faq: string; cta: string };
  hero: { line1: string; marked: string; sub: string; note: string; chips: Record<"busin" | "receipt" | "timetable" | "waiting", string> };
  sections: Record<"day" | "people" | "private" | "download" | "schools" | "faq", { eyebrow: string; title: string; sub: string }>;
  footer: { tagline: string; staff: string; theme: string; rights: string };
  /** A student's morning, one step at a time, each with what the phone shows. */
  day: {
    steps: { time: string; title: string; text: string }[];
    sub: { label: string; route: string; stages: [string, string, string]; push: string; pushTitle: string; semester: string; receipt: string };
    pass: { label: string; name: string; valid: string; offline: string; refresh: string; stop: string };
    live: { label: string; eta: string; stops: [string, string, string]; bus: string };
    board: { label: string; done: string; hello: string; seat: string; next: string };
  };
  people: { cards: { role: string; line: string; points: string[] }[] };
  private: { facts: { title: string; text: string }[] };
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
    chips: { busin: "Your bus is 4 min away", receipt: "The receipt? It was in this bag...", timetable: "The 7:40 bus. Or the 8:10. Who knows.", waiting: "“Five minutes away” since 7:15" },
  },
  sections: {
    day: { eyebrow: "A day with BusIn", title: "From 6:40 to the last bell", sub: "Follow one student through a morning that used to be stressful." },
    people: { eyebrow: "Who it helps", title: "Everyone's day gets easier", sub: "Students, drivers, the people at the door, and the school office." },
    private: { eyebrow: "Yours, and private", title: "Calm by design", sub: "Your school decides who rides. Nobody tracks your phone. It works when the signal does not." },
    download: { eyebrow: "Get BusIn", title: "Take it with you", sub: "The student app for your phone. Staff apps come from your school's admin." },
    schools: { eyebrow: "Schools that chose better", title: "A growing wall of schools that picked quality", sub: "Join the movement of schools that choose innovation for their students." },
    faq: { eyebrow: "Questions", title: "Good to know", sub: "Short answers to what people ask first." },
  },
  day: {
    steps: [
      { time: "6:40", title: "Subscribe once", text: "Pick your stop and your semester, add your receipt from the app. Your school checks it, and your phone tells you when it is approved." },
      { time: "7:05", title: "Your pass, even offline", text: "A code that changes every few seconds, so nobody can borrow a screenshot of it. No signal at the gate? It still works." },
      { time: "7:22", title: "See it coming", text: "The driver starts the trip and the bus appears on your map. You leave when it is close, not when you guess." },
      { time: "7:31", title: "Show, scan, sit", text: "Someone at the door scans your code. A green tick, a good morning, and you are on board." },
    ],
    sub: { label: "Subscription", route: "Campus line, Market stop", stages: ["Sent", "Checking", "Approved"], pushTitle: "BusIn", push: "Your school approved your subscription.", semester: "First semester, Sep to Jan", receipt: "Receipt added" },
    pass: { label: "My pass", name: "Amara N.", valid: "Valid until 31 Jan", offline: "No signal, still works", refresh: "Changes in 12 s", stop: "Market stop, Bus 2" },
    live: { label: "Live", eta: "4 min away", stops: ["Depot", "Your stop", "Campus"], bus: "Bus 2" },
    board: { label: "At the door", done: "On board", hello: "Have a good day, Amara", seat: "7:31, Bus 2", next: "At campus around 7:48" },
  },
  people: {
    cards: [
      { role: "Students", line: "Know when to leave, and ride with a pass that cannot get lost.", points: ["Subscribe from the phone", "A pass that works offline", "The bus on a map"] },
      { role: "Drivers", line: "Start the trip with one tap, and the riders see the bus move.", points: ["Today's trip, ready", "One tap to start and end", "No calls asking where you are"] },
      { role: "Staff at the door", line: "Scan in a second, even with no signal. The list catches up later.", points: ["Instant yes or no", "Works offline", "No paper lists"] },
      { role: "School office", line: "Approve subscriptions, see who rides, and plan buses with real numbers.", points: ["Review receipts in one place", "Every boarding counted", "Stops and buses that fit"] },
    ],
  },
  private: {
    facts: [
      { title: "Your school decides who rides", text: "Subscriptions are approved by your school, and only it sees them." },
      { title: "Nobody tracks your phone", text: "Only the bus shares where it is, and only during a trip." },
      { title: "Made for weak signal", text: "Your pass is kept safely on your phone, so the gate never waits for the network." },
    ],
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
    chips: { busin: "Votre bus arrive dans 4 min", receipt: "Le reçu ? Il était dans ce sac...", timetable: "Le bus de 7 h 40. Ou de 8 h 10. Allez savoir.", waiting: "« Dans cinq minutes » depuis 7 h 15" },
  },
  sections: {
    day: { eyebrow: "Une journée avec BusIn", title: "De 6 h 40 à la dernière sonnerie", sub: "Suivez un étudiant dans un matin qui était stressant." },
    people: { eyebrow: "Qui ça aide", title: "La journée de chacun devient plus simple", sub: "Étudiants, chauffeurs, personnel à la porte et bureau de l'école." },
    private: { eyebrow: "À vous, et privé", title: "Serein par conception", sub: "Votre école décide qui voyage. Personne ne suit votre téléphone. Ça marche même sans réseau." },
    download: { eyebrow: "Obtenir BusIn", title: "Emportez-le avec vous", sub: "L'application étudiante pour votre téléphone. Les applications du personnel viennent de l'administration de votre école." },
    schools: { eyebrow: "Les écoles qui ont choisi mieux", title: "Un mur d'écoles qui grandit, celles qui ont choisi la qualité", sub: "Rejoignez le mouvement des écoles qui choisissent l'innovation pour leurs étudiants." },
    faq: { eyebrow: "Questions", title: "Bon à savoir", sub: "Des réponses courtes à ce qu'on demande en premier." },
  },
  day: {
    steps: [
      { time: "6 h 40", title: "Abonnez-vous une fois", text: "Choisissez votre arrêt et votre semestre, ajoutez votre reçu depuis l'application. Votre école vérifie, et votre téléphone vous prévient quand c'est validé." },
      { time: "7 h 05", title: "Votre pass, même hors ligne", text: "Un code qui change toutes les quelques secondes, pour que personne ne puisse emprunter une capture d'écran. Pas de réseau au portail ? Ça marche quand même." },
      { time: "7 h 22", title: "Voyez-le arriver", text: "Le chauffeur démarre le trajet et le bus apparaît sur votre carte. Vous partez quand il est proche, pas au hasard." },
      { time: "7 h 31", title: "Montrer, scanner, s'asseoir", text: "Quelqu'un à la porte scanne votre code. Une coche verte, un bonjour, et vous êtes à bord." },
    ],
    sub: { label: "Abonnement", route: "Ligne campus, arrêt Marché", stages: ["Envoyé", "En vérification", "Validé"], pushTitle: "BusIn", push: "Votre école a validé votre abonnement.", semester: "Premier semestre, sept. à janv.", receipt: "Reçu ajouté" },
    pass: { label: "Mon pass", name: "Amara N.", valid: "Valide jusqu'au 31 janv.", offline: "Pas de réseau, ça marche", refresh: "Change dans 12 s", stop: "Arrêt Marché, Bus 2" },
    live: { label: "En direct", eta: "À 4 min", stops: ["Dépôt", "Votre arrêt", "Campus"], bus: "Bus 2" },
    board: { label: "À la porte", done: "À bord", hello: "Bonne journée, Amara", seat: "7 h 31, Bus 2", next: "Au campus vers 7 h 48" },
  },
  people: {
    cards: [
      { role: "Étudiants", line: "Savent quand partir, et voyagent avec un pass qui ne se perd pas.", points: ["S'abonner depuis le téléphone", "Un pass qui marche hors ligne", "Le bus sur une carte"] },
      { role: "Chauffeurs", line: "Démarrent le trajet d'un geste, et les passagers voient le bus avancer.", points: ["Le trajet du jour, prêt", "Un geste pour démarrer et finir", "Plus d'appels pour savoir où vous êtes"] },
      { role: "Personnel à la porte", line: "Scanne en une seconde, même sans réseau. La liste se met à jour ensuite.", points: ["Oui ou non, tout de suite", "Marche hors ligne", "Plus de listes papier"] },
      { role: "Bureau de l'école", line: "Valide les abonnements, voit qui voyage, et prévoit les bus avec de vrais chiffres.", points: ["Les reçus au même endroit", "Chaque montée comptée", "Des arrêts et des bus adaptés"] },
    ],
  },
  private: {
    facts: [
      { title: "Votre école décide qui voyage", text: "Les abonnements sont validés par votre école, et elle seule les voit." },
      { title: "Personne ne suit votre téléphone", text: "Seul le bus partage sa position, et seulement pendant un trajet." },
      { title: "Fait pour le réseau faible", text: "Votre pass est gardé en sécurité sur votre téléphone, le portail n'attend jamais le réseau." },
    ],
  },
  footer: { tagline: "Un compagnon pour le trajet de tous les jours.", staff: "Connexion du personnel", theme: "Thème", rights: "BusIn" },
};

export const landingCatalogues: Record<Locale, LandingCopy> = { en, fr };

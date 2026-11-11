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
  footer: {
    tagline: string;
    staff: string;
    theme: string;
    rights: string;
    explore: string;
    forSchools: string;
    legal: { title: string; privacy: string; terms: string; soon: string; credits: string };
  };
  /** The credits page: what the site uses that others made, and under which licence. */
  credits: {
    meta: string;
    title: string;
    intro: string;
    items: { name: string; what: string; licence: string; href: string }[];
    photos: string;
    photoList: { what: string; href: string }[];
    back: string;
  };
  schools: { trusted: string; slot: string; invite: string; lead: string; points: string[] };
  faq: { items: { q: string; a: string }[]; aside: { title: string; text: string; school: string; notify: string } };
  /** A student's morning, one step at a time, each with what the phone shows. */
  day: {
    steps: { time: string; title: string; text: string }[];
    sub: { label: string; route: string; stages: [string, string, string]; push: string; pushTitle: string; semester: string; receipt: string };
    pass: { label: string; name: string; valid: string; offline: string; stop: string };
    live: { label: string; eta: string; stops: [string, string, string]; bus: string };
    board: { label: string; done: string; hello: string; seat: string; next: string };
  };
  people: {
    cards: { role: string; line: string; points: string[]; photo: string }[];
    /** The last card: a photo that opens into Calm by design. */
    invite: { title: string; text: string; photo: string };
  };
  private: { facts: { title: string; text: string }[] };
  download: {
    students: { title: string; text: string; soon: string; notify: string; play: string; apk: string; ios: string };
    team: { title: string; text: string; cta: string };
  };
  form: {
    titles: Record<"school" | "notify", string>;
    descriptions: Record<"school" | "notify", string>;
    email: string;
    name: string;
    organisation: string;
    message: string;
    placeholders: Record<"email" | "name" | "organisation" | "message", string>;
    messageHint: string;
    privacy: string;
    send: string;
    sending: string;
    cancel: string;
    problems: Record<"required" | "email" | "long", string>;
    outcomes: Record<"stored" | "already" | "invalid" | "busy" | "failed", string>;
  };
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
    download: { eyebrow: "Get BusIn", title: "Take it with you", sub: "The student app for your phone, and tools for the team that runs the buses." },
    schools: { eyebrow: "Schools that chose better", title: "A growing wall of schools that picked quality", sub: "Join the movement of schools that choose innovation for their students." },
    faq: { eyebrow: "Questions", title: "Good to know", sub: "Short answers to what people ask first." },
  },
  day: {
    steps: [
      { time: "6:40", title: "Subscribe once", text: "Pick your stop and your semester, add your receipt from the app. Your school checks it, and your phone tells you when it is approved." },
      { time: "7:05", title: "Your pass, even offline", text: "Your pass lives in the app, ready at the gate. No signal there? It still works." },
      { time: "7:22", title: "See it coming", text: "The driver starts the trip and the bus appears on your map. You leave when it is close, not when you guess." },
      { time: "7:31", title: "Show, scan, sit", text: "Someone at the door scans your code. A green tick, a good morning, and you are on board." },
    ],
    sub: { label: "Subscription", route: "Campus line, Market stop", stages: ["Sent", "Checking", "Approved"], pushTitle: "BusIn", push: "Your school approved your subscription.", semester: "First semester, Sep to Jan", receipt: "Receipt added" },
    pass: { label: "My pass", name: "Amara N.", valid: "Valid until 31 Jan", offline: "No signal, still works", stop: "Market stop, Bus 2" },
    live: { label: "Live", eta: "4 min away", stops: ["Depot", "Your stop", "Campus"], bus: "Bus 2" },
    board: { label: "At the door", done: "On board", hello: "Have a good day, Amara", seat: "7:31, Bus 2", next: "At campus around 7:48" },
  },
  people: {
    cards: [
      { role: "Students", line: "Know when to leave, and ride with a pass that cannot get lost.", points: ["Subscribe from the phone", "A pass that works offline", "The bus on a map"], photo: "Two students looking at a phone together and smiling" },
      { role: "Drivers", line: "Start the trip with one tap, and the riders see the bus move.", points: ["Today's trip, ready", "One tap to start and end", "No calls asking where you are"], photo: "A driver behind the window of a school bus" },
      { role: "Staff at the door", line: "Scan in a second, even with no signal. The list catches up later.", points: ["Instant yes or no", "Works offline", "No paper lists"], photo: "A worker in a safety vest leaning on a bus shelter, checking his phone" },
      { role: "School office", line: "Approve subscriptions, see who rides, and plan buses with real numbers.", points: ["Review receipts in one place", "Every boarding counted", "Stops and buses that fit"], photo: "A man at an office desk going through papers, stacks of files beside him" },
    ],
    invite: {
      title: "A calmer ride, for everyone",
      text: "And behind every quiet morning, a promise about what is yours.",
      photo: "A blue and white city bus at a stop beside a busy road, seen from above, with people waiting on the pavement",
    },
  },
  private: {
    facts: [
      { title: "Your school decides who rides", text: "Subscriptions are approved by your school, and only it sees them." },
      { title: "Nobody tracks your phone", text: "Only the bus shares where it is, and only during a trip. If you ask to see yourself on the map, your position stays on your phone." },
      { title: "Made for weak signal", text: "Your pass is kept safely on your phone, so the gate never waits for the network." },
    ],
  },
  download: {
    students: {
      title: "For students",
      text: "On Android and iPhone: subscribe, carry your pass, see the bus coming.",
      soon: "Coming soon",
      notify: "Get notified",
      play: "Get it on Google Play",
      apk: "Download the APK",
      ios: "Download on the App Store",
    },
    team: {
      title: "For the school team",
      text: "Drivers, the staff at the door and the school office each get the tools for their part of the day, set up together with the school.",
      cta: "Invite your school",
    },
  },
  form: {
    titles: { school: "Bring BusIn to your school", notify: "Tell me when the app is out" },
    descriptions: {
      school: "Tell us who you are and we will get back to you to set your school up.",
      notify: "Leave your address and we will write once, when the app is ready.",
    },
    email: "Email",
    name: "Your name",
    organisation: "School",
    message: "Anything to add",
    placeholders: { email: "you@example.com", name: "First and last name", organisation: "Your school's name", message: "Two buses, about 300 students..." },
    messageHint: "How many students ride, how many buses: anything helps.",
    privacy: "We use your address only to answer this request.",
    send: "Send",
    sending: "Sending...",
    cancel: "Cancel",
    problems: { required: "Fill this in.", email: "This does not look like an email address.", long: "This is too long." },
    outcomes: {
      stored: "Thank you. We will be in touch.",
      already: "You already asked, and we have it. We will be in touch.",
      invalid: "Something in the form is not right. Check it and try again.",
      busy: "Too many requests just now. Try again in an hour.",
      failed: "It did not go through. Try again in a moment.",
    },
  },
  schools: {
    trusted: "Rides with BusIn",
    slot: "Your school here",
    invite: "Invite your school",
    lead: "One admin sets it up in an afternoon: stops, buses, the semester. Students subscribe from their phones the same day.",
    points: ["No hardware to buy", "Your data stays your school's", "English and French"],
  },
  faq: {
    items: [
      { q: "Is BusIn free for students?", a: "Yes. Your school sets it up and decides how the bus itself is paid for. The app costs you nothing." },
      { q: "My school is not on BusIn. What can I do?", a: "Invite it: leave your school's name and your address, and we will get in touch with the people who run the buses." },
      { q: "Do I need data to show my pass?", a: "No. Once you have opened the app with a signal, your pass works without one, and the scan at the door does too." },
      { q: "Does BusIn know where I am?", a: "No. The app reads your position only when you ask: to show you on the map next to your stop and the bus (it stays on your phone), or once, rounded to about 500 metres, if you choose to tell your school roughly where you live so it can place stops. Only the bus shares where it is, and only while a trip is running." },
      { q: "Do I need a school email?", a: "Not always. With your school email you are in straight away. If your school also accepts other addresses, you can join with a personal Google account and the school checks that you are one of its students." },
      { q: "Who sees my subscription and my receipt?", a: "Only the admins of your school. Nobody at another school, and no other student, can see them." },
      { q: "How do drivers and staff get their app?", a: "Their school sets them up with it, along with their account. Students never need it." },
    ],
    aside: {
      title: "Not on BusIn yet?",
      text: "Invite your school and we will talk to the people who run its buses. Or leave your address to hear when the app is out.",
      school: "Invite your school",
      notify: "Get notified",
    },
  },
  credits: {
    meta: "Credits: what BusIn's site uses that others made",
    title: "Credits",
    intro: "This site is built with the work of others. Thank you to them; here is what we use and under which licence.",
    items: [
      { name: "Thiings", what: "The 3D stickers and objects", licence: "Thiings licence", href: "https://www.thiings.co" },
      { name: "Pexels", what: "The photographs", licence: "Pexels licence", href: "https://www.pexels.com/license/" },
      { name: "Hugeicons", what: "The icons", licence: "MIT", href: "https://hugeicons.com" },
      { name: "Plus Jakarta Sans", what: "The typeface", licence: "SIL Open Font License 1.1", href: "https://fonts.google.com/specimen/Plus+Jakarta+Sans" },
      { name: "GSAP", what: "The motion", licence: "GSAP standard licence", href: "https://gsap.com/standard-license" },
    ],
    photos: "Photographs from Pexels",
    photoList: [
      { what: "Students sharing a phone", href: "https://www.pexels.com/photo/happy-diverse-students-sharing-smartphone-together-and-smiling-6147067/" },
      { what: "A bus driver behind the window", href: "https://www.pexels.com/photo/yellow-bus-and-driver-sitting-behind-window-19928045/" },
      { what: "A worker at a bus shelter", href: "https://www.pexels.com/photo/utility-person-leaning-on-a-waiting-shed-13408573/" },
      { what: "An office with stacks of papers", href: "https://www.pexels.com/photo/man-in-white-long-sleeve-shirt-sitting-on-black-chair-holding-white-papers-7654121/" },
      { what: "A bus stop seen from above", href: "https://www.pexels.com/photo/21576182/" },
    ],
    back: "Back to BusIn",
  },
  footer: { tagline: "A companion for the daily ride.", staff: "Staff sign in", theme: "Theme", rights: "BusIn", explore: "On this page", forSchools: "For schools", legal: { title: "Legal and credits", privacy: "Privacy", terms: "Terms of use", soon: "Soon", credits: "Credits" } },
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
    download: { eyebrow: "Obtenir BusIn", title: "Emportez-le avec vous", sub: "L'application étudiante pour votre téléphone, et des outils pour l'équipe qui gère les bus." },
    schools: { eyebrow: "Les écoles qui ont choisi mieux", title: "Un mur d'écoles qui grandit, celles qui ont choisi la qualité", sub: "Rejoignez le mouvement des écoles qui choisissent l'innovation pour leurs étudiants." },
    faq: { eyebrow: "Questions", title: "Bon à savoir", sub: "Des réponses courtes à ce qu'on demande en premier." },
  },
  day: {
    steps: [
      { time: "6 h 40", title: "Abonnez-vous une fois", text: "Choisissez votre arrêt et votre semestre, ajoutez votre reçu depuis l'application. Votre école vérifie, et votre téléphone vous prévient quand c'est validé." },
      { time: "7 h 05", title: "Votre pass, même hors ligne", text: "Votre pass vit dans l'application, prêt au portail. Pas de réseau ? Ça marche quand même." },
      { time: "7 h 22", title: "Voyez-le arriver", text: "Le chauffeur démarre le trajet et le bus apparaît sur votre carte. Vous partez quand il est proche, pas au hasard." },
      { time: "7 h 31", title: "Montrer, scanner, s'asseoir", text: "Quelqu'un à la porte scanne votre code. Une coche verte, un bonjour, et vous êtes à bord." },
    ],
    sub: { label: "Abonnement", route: "Ligne campus, arrêt Marché", stages: ["Envoyé", "En vérification", "Validé"], pushTitle: "BusIn", push: "Votre école a validé votre abonnement.", semester: "Premier semestre, sept. à janv.", receipt: "Reçu ajouté" },
    pass: { label: "Mon pass", name: "Amara N.", valid: "Valide jusqu'au 31 janv.", offline: "Pas de réseau, ça marche", stop: "Arrêt Marché, Bus 2" },
    live: { label: "En direct", eta: "À 4 min", stops: ["Dépôt", "Votre arrêt", "Campus"], bus: "Bus 2" },
    board: { label: "À la porte", done: "À bord", hello: "Bonne journée, Amara", seat: "7 h 31, Bus 2", next: "Au campus vers 7 h 48" },
  },
  people: {
    cards: [
      { role: "Étudiants", line: "Savent quand partir, et voyagent avec un pass qui ne se perd pas.", points: ["S'abonner depuis le téléphone", "Un pass qui marche hors ligne", "Le bus sur une carte"], photo: "Deux étudiants regardent un téléphone ensemble en souriant" },
      { role: "Chauffeurs", line: "Démarrent le trajet d'un geste, et les passagers voient le bus avancer.", points: ["Le trajet du jour, prêt", "Un geste pour démarrer et finir", "Plus d'appels pour savoir où vous êtes"], photo: "Un chauffeur derrière la vitre d'un bus scolaire" },
      { role: "Personnel à la porte", line: "Scanne en une seconde, même sans réseau. La liste se met à jour ensuite.", points: ["Oui ou non, tout de suite", "Marche hors ligne", "Plus de listes papier"], photo: "Un agent en gilet de sécurité appuyé contre un abri de bus, son téléphone en main" },
      { role: "Bureau de l'école", line: "Valide les abonnements, voit qui voyage, et prévoit les bus avec de vrais chiffres.", points: ["Les reçus au même endroit", "Chaque montée comptée", "Des arrêts et des bus adaptés"], photo: "Un homme à son bureau parcourt des papiers, des piles de dossiers à côté de lui" },
    ],
    invite: {
      title: "Un trajet plus serein, pour tous",
      text: "Et derrière chaque matin tranquille, une promesse sur ce qui est à vous.",
      photo: "Un bus bleu et blanc à un arrêt au bord d'une route animée, vu d'en haut, des gens attendent sur le trottoir",
    },
  },
  private: {
    facts: [
      { title: "Votre école décide qui voyage", text: "Les abonnements sont validés par votre école, et elle seule les voit." },
      { title: "Personne ne suit votre téléphone", text: "Seul le bus partage sa position, et seulement pendant un trajet. Si vous demandez à vous voir sur la carte, votre position reste sur votre téléphone." },
      { title: "Fait pour le réseau faible", text: "Votre pass est gardé en sécurité sur votre téléphone, le portail n'attend jamais le réseau." },
    ],
  },
  download: {
    students: {
      title: "Pour les étudiants",
      text: "Sur Android et iPhone : abonnez-vous, gardez votre pass, voyez le bus arriver.",
      soon: "Bientôt",
      notify: "Me prévenir",
      play: "Disponible sur Google Play",
      apk: "Télécharger l'APK",
      ios: "Télécharger dans l'App Store",
    },
    team: {
      title: "Pour l'équipe de l'école",
      text: "Chauffeurs, personnel à la porte et bureau de l'école ont chacun les outils de leur part de la journée, installés avec l'école.",
      cta: "Inviter votre école",
    },
  },
  form: {
    titles: { school: "Amenez BusIn dans votre école", notify: "Prévenez-moi à la sortie de l'application" },
    descriptions: {
      school: "Dites-nous qui vous êtes, nous revenons vers vous pour installer votre école.",
      notify: "Laissez votre adresse, nous écrirons une fois, quand l'application sera prête.",
    },
    email: "E-mail",
    name: "Votre nom",
    organisation: "École",
    message: "Autre chose à ajouter",
    placeholders: { email: "vous@exemple.com", name: "Prénom et nom", organisation: "Le nom de votre école", message: "Deux bus, environ 300 étudiants..." },
    messageHint: "Combien d'étudiants voyagent, combien de bus : tout aide.",
    privacy: "Votre adresse sert uniquement à répondre à cette demande.",
    send: "Envoyer",
    sending: "Envoi...",
    cancel: "Annuler",
    problems: { required: "À remplir.", email: "Cela ne ressemble pas à une adresse e-mail.", long: "C'est trop long." },
    outcomes: {
      stored: "Merci. Nous revenons vers vous.",
      already: "Vous l'avez déjà demandé, c'est noté. Nous revenons vers vous.",
      invalid: "Quelque chose ne va pas dans le formulaire. Vérifiez et réessayez.",
      busy: "Trop de demandes en ce moment. Réessayez dans une heure.",
      failed: "L'envoi n'a pas abouti. Réessayez dans un instant.",
    },
  },
  schools: {
    trusted: "Roule avec BusIn",
    slot: "Votre école ici",
    invite: "Inviter votre école",
    lead: "Un administrateur l'installe en un après-midi : arrêts, bus, semestre. Les étudiants s'abonnent depuis leur téléphone le jour même.",
    points: ["Aucun matériel à acheter", "Vos données restent à votre école", "Anglais et français"],
  },
  faq: {
    items: [
      { q: "BusIn est-il gratuit pour les étudiants ?", a: "Oui. Votre école l'installe et décide comment le bus lui-même est payé. L'application ne vous coûte rien." },
      { q: "Mon école n'utilise pas BusIn. Que faire ?", a: "Invitez-la : laissez le nom de votre école et votre adresse, nous contacterons les personnes qui gèrent les bus." },
      { q: "Faut-il des données pour montrer mon pass ?", a: "Non. Une fois l'application ouverte avec du réseau, votre pass marche sans, et le scan à la porte aussi." },
      { q: "BusIn sait-il où je suis ?", a: "Non. L'application lit votre position seulement quand vous le demandez : pour vous montrer sur la carte près de votre arrêt et du bus (elle reste sur votre téléphone), ou une fois, arrondie à environ 500 mètres, si vous choisissez d'indiquer à votre école à peu près où vous habitez pour l'aider à placer les arrêts. Seul le bus partage sa position, et seulement pendant un trajet." },
      { q: "Faut-il un e-mail scolaire ?", a: "Pas toujours. Avec votre e-mail scolaire, vous entrez tout de suite. Si votre école accepte aussi d'autres adresses, vous pouvez la rejoindre avec un compte Google personnel, et l'école vérifie que vous êtes bien l'un de ses étudiants." },
      { q: "Qui voit mon abonnement et mon reçu ?", a: "Seuls les administrateurs de votre école. Personne d'une autre école, ni aucun autre étudiant, ne peut les voir." },
      { q: "Comment les chauffeurs et le personnel obtiennent-ils leur application ?", a: "Leur école le leur installe, avec leur compte. Les étudiants n'en ont jamais besoin." },
    ],
    aside: {
      title: "Pas encore sur BusIn ?",
      text: "Invitez votre école, nous parlerons aux personnes qui gèrent ses bus. Ou laissez votre adresse pour savoir quand l'application sort.",
      school: "Inviter votre école",
      notify: "Me prévenir",
    },
  },
  credits: {
    meta: "Crédits : ce que le site de BusIn utilise et que d'autres ont créé",
    title: "Crédits",
    intro: "Ce site est construit avec le travail d'autres personnes. Merci à elles ; voici ce que nous utilisons et sous quelle licence.",
    items: [
      { name: "Thiings", what: "Les autocollants et objets en 3D", licence: "Licence Thiings", href: "https://www.thiings.co" },
      { name: "Pexels", what: "Les photographies", licence: "Licence Pexels", href: "https://www.pexels.com/license/" },
      { name: "Hugeicons", what: "Les icônes", licence: "MIT", href: "https://hugeicons.com" },
      { name: "Plus Jakarta Sans", what: "La police de caractères", licence: "SIL Open Font License 1.1", href: "https://fonts.google.com/specimen/Plus+Jakarta+Sans" },
      { name: "GSAP", what: "Les animations", licence: "Licence standard GSAP", href: "https://gsap.com/standard-license" },
    ],
    photos: "Photographies de Pexels",
    photoList: [
      { what: "Des étudiants partagent un téléphone", href: "https://www.pexels.com/photo/happy-diverse-students-sharing-smartphone-together-and-smiling-6147067/" },
      { what: "Un chauffeur de bus derrière la vitre", href: "https://www.pexels.com/photo/yellow-bus-and-driver-sitting-behind-window-19928045/" },
      { what: "Un agent à un abri de bus", href: "https://www.pexels.com/photo/utility-person-leaning-on-a-waiting-shed-13408573/" },
      { what: "Un bureau avec des piles de papiers", href: "https://www.pexels.com/photo/man-in-white-long-sleeve-shirt-sitting-on-black-chair-holding-white-papers-7654121/" },
      { what: "Un arrêt de bus vu d'en haut", href: "https://www.pexels.com/photo/21576182/" },
    ],
    back: "Retour à BusIn",
  },
  footer: { tagline: "Un compagnon pour le trajet de tous les jours.", staff: "Connexion du personnel", theme: "Thème", rights: "BusIn", explore: "Sur cette page", forSchools: "Pour les écoles", legal: { title: "Mentions et crédits", privacy: "Confidentialité", terms: "Conditions d'utilisation", soon: "Bientôt", credits: "Crédits" } },
};

export const landingCatalogues: Record<Locale, LandingCopy> = { en, fr };

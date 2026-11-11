/// The short lines shown when a student's code is scanned at the door, in English and French. A line fits the moment:
/// the time of day, the day of the week, where the semester is, and a ride milestone when there is one. The pick is
/// stable for a given boarding (it depends on the boarding's id), so reopening the app shows the same line.
library;

enum DayPart { early, morning, midday, evening }

enum SemesterPhase { start, middle, end }

/// What is known about a boarding when its line is chosen.
class BoardingMoment {
  const BoardingMoment({required this.at, this.phase = SemesterPhase.middle, this.rideNumber});

  /// The wall-clock time at the school.
  final DateTime at;
  final SemesterPhase phase;

  /// The student's ride count this semester, this boarding included, when it is known.
  final int? rideNumber;

  DayPart get dayPart => switch (at.hour) {
        < 7 => DayPart.early,
        < 11 => DayPart.morning,
        < 15 => DayPart.midday,
        _ => DayPart.evening,
      };
}

/// Where a date sits in a semester: its first two weeks, its last two weeks, or the rest.
SemesterPhase phaseOf(DateTime day, DateTime start, DateTime end) {
  if (day.difference(start).inDays < 14) return SemesterPhase.start;
  if (end.difference(day).inDays < 14) return SemesterPhase.end;
  return SemesterPhase.middle;
}

/// The rides that earn their own line.
const boardingMilestones = [1, 10, 25, 50, 100];

const _en = <String, Object>{
  'milestone': {
    '1': ['First ride of the semester. Welcome aboard.'],
    '10': ['Ten rides this semester. You know the way by now.'],
    '25': ['Twenty-five rides. The bus would miss you if you stopped.'],
    '50': ['Fifty rides this semester. That is a lot of mornings.'],
    '100': ['A hundred rides. The driver should know your name.'],
  },
  'dayPart': {
    'early': [
      'Up before the sun. Respect.',
      'Early bird, warm seat.',
      'The town is still asleep. You are not.',
      'An early start makes a calm day.',
      'First on, first settled.',
      'Quiet roads, easy ride.',
      'Coffee later. Bus now.',
      'You beat the alarm clock today.',
    ],
    'morning': [
      'Good morning. On board and on time.',
      'Settle in. The day starts here.',
      'Morning ride, fresh start.',
      'You made it. The rest of the day will follow.',
      'Seat found, day begun.',
      'Breathe out. You are on your way.',
      'Right on time for a good day.',
      'Morning sorted. Classes next.',
    ],
    'midday': [
      'Midday ride. Halfway through the day.',
      'Lunch on the move.',
      'On board. Take a breather.',
      'Middle of the day, middle of the road.',
      'A short rest between two busy halves.',
      'Good timing. The bus waited for no one, and you did not need it to.',
      'Sun up high, you on board.',
      'The afternoon can wait a few stops.',
    ],
    'evening': [
      'Heading home. Well done today.',
      'Day done. Let the bus do the rest.',
      'Evening ride. You earned this seat.',
      'Home stretch.',
      'Rest your feet. Home is coming.',
      'Another day in the books.',
      'Lights on, ride home.',
      'Good work today. Enjoy the ride.',
    ],
  },
  'weekday': {
    'monday': [
      'Monday, handled.',
      'New week, same reliable ride.',
      'Mondays are easier sitting down.',
      'Fresh week. You started it on time.',
      'One Monday down.',
      'The week starts here, on board.',
    ],
    'friday': [
      'Friday ride. The weekend is close.',
      'Last stretch of the week.',
      'Friday. You made it all week.',
      'Almost the weekend. Enjoy the ride.',
      'End of the week, start of the rest.',
      'Friday feeling, on board.',
    ],
    'weekend': [
      'A weekend ride. Dedication.',
      'Weekend on the bus. Something important today?',
      'Quiet bus, weekend pace.',
      'Even on the weekend, right on time.',
      'Saturday or Sunday, the bus is here for you.',
      'Weekend plans, sorted.',
    ],
  },
  'phase': {
    'start': [
      'New semester, new routine. Welcome aboard.',
      'The semester is young. Good start.',
      'Week one energy.',
      'Settling into the semester, one ride at a time.',
      'A fresh semester and a seat to match.',
      'Starting the semester the right way.',
      'Learning the route? You have got it.',
      'Early in the semester and already on time.',
    ],
    'end': [
      'Nearly the end of the semester. Keep going.',
      'Final stretch of the semester.',
      'Exams soon. Breathe. Ride.',
      'The semester is almost done. So is this ride.',
      'Last weeks. You have got this.',
      'Hold on, the break is close.',
      'End of semester focus, on board.',
      'Almost there. One ride at a time.',
    ],
  },
  'general': [
    'On board. Have a good day.',
    'Welcome aboard.',
    'Scanned and seated.',
    'You are on. Enjoy the ride.',
    'All set. Next stop: your day.',
    'That was quick. Find a seat.',
    'No queue, no fuss. You are in.',
    'Ride smooth.',
    'Glad you are here.',
    'Take a seat, take a breath.',
    'The bus is better with you on it.',
    'Your pass did its job. Now relax.',
    'In and seated. Nice.',
    'Safe ride.',
    'Make yourself comfortable.',
    'You are exactly where you should be.',
    'Ticket checked. Mind at ease.',
    'Another smooth start.',
    'Good to see you.',
    'Hop on, look out, enjoy.',
  ],
};

const _fr = <String, Object>{
  'milestone': {
    '1': ['Premier trajet du semestre. Bienvenue à bord.'],
    '10': ['Dix trajets ce semestre. Vous connaissez la route.'],
    '25': ['Vingt-cinq trajets. Le bus vous regretterait.'],
    '50': ['Cinquante trajets ce semestre. Ça fait beaucoup de matins.'],
    '100': ['Cent trajets. Le chauffeur devrait connaître votre nom.'],
  },
  'dayPart': {
    'early': [
      'Debout avant le soleil. Respect.',
      'Lève-tôt, place au chaud.',
      'La ville dort encore. Pas vous.',
      'Un départ tôt pour une journée calme.',
      'Premier monté, premier installé.',
      'Routes calmes, trajet facile.',
      'Le café attendra. Le bus, non.',
      'Vous avez battu le réveil aujourd’hui.',
    ],
    'morning': [
      'Bonjour. À bord et à l’heure.',
      'Installez-vous. La journée commence ici.',
      'Trajet du matin, nouveau départ.',
      'Vous y êtes. Le reste de la journée suivra.',
      'Place trouvée, journée lancée.',
      'Respirez. Vous êtes en route.',
      'Pile à l’heure pour une bonne journée.',
      'Matin réglé. Les cours ensuite.',
    ],
    'midday': [
      'Trajet de midi. La moitié de la journée.',
      'Déjeuner en route.',
      'À bord. Faites une pause.',
      'Milieu de journée, milieu de route.',
      'Un petit repos entre deux moitiés chargées.',
      'Bon timing. Le bus n’attend personne, et vous n’en aviez pas besoin.',
      'Soleil haut, vous à bord.',
      'L’après-midi peut attendre quelques arrêts.',
    ],
    'evening': [
      'Retour à la maison. Bravo pour aujourd’hui.',
      'Journée finie. Le bus s’occupe du reste.',
      'Trajet du soir. Vous avez mérité cette place.',
      'Dernière ligne droite.',
      'Reposez vos pieds. La maison approche.',
      'Encore une journée de faite.',
      'Lumières allumées, retour au calme.',
      'Beau travail aujourd’hui. Bon trajet.',
    ],
  },
  'weekday': {
    'monday': [
      'Lundi, maîtrisé.',
      'Nouvelle semaine, même trajet fiable.',
      'Les lundis passent mieux assis.',
      'Nouvelle semaine. Vous l’avez commencée à l’heure.',
      'Un lundi de moins.',
      'La semaine commence ici, à bord.',
    ],
    'friday': [
      'Trajet du vendredi. Le week-end approche.',
      'Dernière ligne droite de la semaine.',
      'Vendredi. Vous avez tenu toute la semaine.',
      'Bientôt le week-end. Bon trajet.',
      'Fin de semaine, début du repos.',
      'Ambiance vendredi, à bord.',
    ],
    'weekend': [
      'Un trajet le week-end. Quelle motivation.',
      'Le bus le week-end. Quelque chose d’important aujourd’hui ?',
      'Bus calme, rythme du week-end.',
      'Même le week-end, pile à l’heure.',
      'Samedi ou dimanche, le bus est là pour vous.',
      'Programme du week-end, réglé.',
    ],
  },
  'phase': {
    'start': [
      'Nouveau semestre, nouvelle routine. Bienvenue à bord.',
      'Le semestre est jeune. Bon départ.',
      'Énergie de première semaine.',
      'On prend ses marques, un trajet à la fois.',
      'Un nouveau semestre et une place assortie.',
      'Commencer le semestre du bon pied.',
      'Vous apprenez la route ? C’est en bonne voie.',
      'Début de semestre et déjà à l’heure.',
    ],
    'end': [
      'Presque la fin du semestre. Continuez.',
      'Dernière ligne droite du semestre.',
      'Les examens approchent. Respirez. Roulez.',
      'Le semestre se termine. Ce trajet aussi.',
      'Dernières semaines. Vous allez y arriver.',
      'Tenez bon, les vacances approchent.',
      'Concentration de fin de semestre, à bord.',
      'Presque fini. Un trajet à la fois.',
    ],
  },
  'general': [
    'À bord. Bonne journée.',
    'Bienvenue à bord.',
    'Scanné et installé.',
    'C’est bon. Bon trajet.',
    'Tout est prêt. Prochain arrêt : votre journée.',
    'C’était rapide. Trouvez une place.',
    'Pas de file, pas de souci. Vous êtes à bord.',
    'Bonne route.',
    'Content de vous voir.',
    'Prenez place, prenez une pause.',
    'Le bus est mieux avec vous dedans.',
    'Votre pass a fait son travail. Détendez-vous.',
    'Monté et assis. Parfait.',
    'Bon voyage.',
    'Installez-vous confortablement.',
    'Vous êtes exactement où il faut.',
    'Pass vérifié. Esprit tranquille.',
    'Encore un départ sans accroc.',
    'Ravi de vous voir.',
    'Montez, regardez dehors, profitez.',
  ],
};

/// Every line of a language (for tests).
List<String> allBoardingLines(String languageCode) {
  final lines = languageCode == 'fr' ? _fr : _en;
  return [
    for (final group in lines.values)
      if (group is Map<String, List<String>>) ...group.values.expand((l) => l) else ...group as List<String>,
  ];
}

/// A small, stable hash (FNV-1a): the same id always picks the same line, on every run and every phone.
int _stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// The line for a boarding. A milestone ride gets its own line; otherwise the line comes from those that fit the time
/// of day, the weekday and the semester phase, plus the general ones. [seed] is the boarding's id.
String boardingLine(BoardingMoment moment, {required String seed, required String languageCode}) {
  final lines = languageCode == 'fr' ? _fr : _en;
  final milestones = lines['milestone']! as Map<String, List<String>>;
  final ride = moment.rideNumber;
  if (ride != null && boardingMilestones.contains(ride)) return milestones['$ride']!.first;

  final weekday = switch (moment.at.weekday) {
    DateTime.monday => 'monday',
    DateTime.friday => 'friday',
    DateTime.saturday || DateTime.sunday => 'weekend',
    _ => null,
  };
  final dayParts = lines['dayPart']! as Map<String, List<String>>;
  final weekdays = lines['weekday']! as Map<String, List<String>>;
  final phases = lines['phase']! as Map<String, List<String>>;
  final pool = <String>[
    ...dayParts[moment.dayPart.name]!,
    if (weekday != null) ...weekdays[weekday]!,
    if (moment.phase != SemesterPhase.middle) ...phases[moment.phase.name]!,
    ...lines['general']! as List<String>,
  ];
  return pool[_stableHash(seed) % pool.length];
}

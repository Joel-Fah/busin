/// Report model for student complaints / feedback about bus service.
///
/// Each report belongs to a [ReportSubject] category with an assigned
/// [ReportPriority], and tracks its lifecycle via [ReportStatus].

// ─── Enums ───────────────────────────────────────────────────────────

/// Priority levels that determine how urgently admins should address a report.
enum ReportPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  final String value;
  const ReportPriority(this.value);

  static ReportPriority from(String value) {
    return ReportPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportPriority.medium,
    );
  }

  String get labelEn {
    switch (this) {
      case ReportPriority.low:
        return 'Low';
      case ReportPriority.medium:
        return 'Medium';
      case ReportPriority.high:
        return 'High';
      case ReportPriority.critical:
        return 'Critical';
    }
  }

  String get labelFr {
    switch (this) {
      case ReportPriority.low:
        return 'Faible';
      case ReportPriority.medium:
        return 'Moyen';
      case ReportPriority.high:
        return 'Élevé';
      case ReportPriority.critical:
        return 'Critique';
    }
  }

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelFr;
}

/// Predefined subjects (categories) for reports. Each carries a default
/// [ReportPriority] so that admins can triage at a glance.
enum ReportSubject {
  busBreakdown('bus_breakdown', ReportPriority.critical),
  safetyIncident('safety_incident', ReportPriority.critical),
  driverBehavior('driver_behavior', ReportPriority.high),
  routeIssue('route_issue', ReportPriority.high),
  scheduleDelay('schedule_delay', ReportPriority.medium),
  overcrowding('overcrowding', ReportPriority.medium),
  cleanlinessHygiene('cleanliness_hygiene', ReportPriority.medium),
  lostItem('lost_item', ReportPriority.medium),
  paymentBilling('payment_billing', ReportPriority.high),
  busStopIssue('bus_stop_issue', ReportPriority.low),
  suggestion('suggestion', ReportPriority.low),
  other('other', ReportPriority.low);

  final String value;
  final ReportPriority defaultPriority;
  const ReportSubject(this.value, this.defaultPriority);

  static ReportSubject from(String value) {
    return ReportSubject.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportSubject.other,
    );
  }

  // ── English labels ──

  String get labelEn {
    switch (this) {
      case ReportSubject.busBreakdown:
        return 'Bus Breakdown';
      case ReportSubject.safetyIncident:
        return 'Safety Incident';
      case ReportSubject.driverBehavior:
        return 'Driver Behavior';
      case ReportSubject.routeIssue:
        return 'Route Issue';
      case ReportSubject.scheduleDelay:
        return 'Schedule / Delay';
      case ReportSubject.overcrowding:
        return 'Overcrowding';
      case ReportSubject.cleanlinessHygiene:
        return 'Cleanliness & Hygiene';
      case ReportSubject.lostItem:
        return 'Lost Item';
      case ReportSubject.paymentBilling:
        return 'Payment / Billing';
      case ReportSubject.busStopIssue:
        return 'Bus Stop Issue';
      case ReportSubject.suggestion:
        return 'Suggestion';
      case ReportSubject.other:
        return 'Other';
    }
  }

  // ── French labels ──

  String get labelFr {
    switch (this) {
      case ReportSubject.busBreakdown:
        return 'Panne de bus';
      case ReportSubject.safetyIncident:
        return 'Incident de sécurité';
      case ReportSubject.driverBehavior:
        return 'Comportement du chauffeur';
      case ReportSubject.routeIssue:
        return 'Problème d\'itinéraire';
      case ReportSubject.scheduleDelay:
        return 'Horaire / Retard';
      case ReportSubject.overcrowding:
        return 'Surcharge';
      case ReportSubject.cleanlinessHygiene:
        return 'Propreté & Hygiène';
      case ReportSubject.lostItem:
        return 'Objet perdu';
      case ReportSubject.paymentBilling:
        return 'Paiement / Facturation';
      case ReportSubject.busStopIssue:
        return 'Problème d\'arrêt';
      case ReportSubject.suggestion:
        return 'Suggestion';
      case ReportSubject.other:
        return 'Autre';
    }
  }

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelFr;

  // ── Hint text (placeholder for the description field) ──

  String get hintTextEn {
    switch (this) {
      case ReportSubject.busBreakdown:
        return 'Describe what happened and the bus location...';
      case ReportSubject.safetyIncident:
        return 'Describe the incident in detail...';
      case ReportSubject.driverBehavior:
        return 'Describe the situation you experienced...';
      case ReportSubject.routeIssue:
        return 'What route problem did you notice?';
      case ReportSubject.scheduleDelay:
        return 'How long was the delay? Which trip?';
      case ReportSubject.overcrowding:
        return 'Which bus/route was overcrowded?';
      case ReportSubject.cleanlinessHygiene:
        return 'Describe the cleanliness issue...';
      case ReportSubject.lostItem:
        return 'Describe the item and where you think you lost it...';
      case ReportSubject.paymentBilling:
        return 'Describe the payment or billing issue...';
      case ReportSubject.busStopIssue:
        return 'Which bus stop? What is the issue?';
      case ReportSubject.suggestion:
        return 'Share your idea to improve the service...';
      case ReportSubject.other:
        return 'Describe your concern in detail...';
    }
  }

  String get hintTextFr {
    switch (this) {
      case ReportSubject.busBreakdown:
        return 'Décrivez ce qui s\'est passé et la position du bus...';
      case ReportSubject.safetyIncident:
        return 'Décrivez l\'incident en détail...';
      case ReportSubject.driverBehavior:
        return 'Décrivez la situation que vous avez vécue...';
      case ReportSubject.routeIssue:
        return 'Quel problème d\'itinéraire avez-vous remarqué ?';
      case ReportSubject.scheduleDelay:
        return 'Quelle était la durée du retard ? Quel trajet ?';
      case ReportSubject.overcrowding:
        return 'Quel bus/trajet était surchargé ?';
      case ReportSubject.cleanlinessHygiene:
        return 'Décrivez le problème de propreté...';
      case ReportSubject.lostItem:
        return 'Décrivez l\'objet et où vous pensez l\'avoir perdu...';
      case ReportSubject.paymentBilling:
        return 'Décrivez le problème de paiement ou facturation...';
      case ReportSubject.busStopIssue:
        return 'Quel arrêt ? Quel est le problème ?';
      case ReportSubject.suggestion:
        return 'Partagez votre idée pour améliorer le service...';
      case ReportSubject.other:
        return 'Décrivez votre préoccupation en détail...';
    }
  }

  String hintText(String languageCode) =>
      languageCode == 'en' ? hintTextEn : hintTextFr;
}

/// Lifecycle status of a report.
enum ReportStatus {
  pending('pending'),
  inReview('in_review'),
  resolved('resolved');

  final String value;
  const ReportStatus(this.value);

  static ReportStatus from(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.pending,
    );
  }

  String get labelEn {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.resolved:
        return 'Resolved';
    }
  }

  String get labelFr {
    switch (this) {
      case ReportStatus.pending:
        return 'En attente';
      case ReportStatus.inReview:
        return 'En cours';
      case ReportStatus.resolved:
        return 'Résolu';
    }
  }

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelFr;

  bool get isPending => this == ReportStatus.pending;
  bool get isInReview => this == ReportStatus.inReview;
  bool get isResolved => this == ReportStatus.resolved;
}

// ─── Model ───────────────────────────────────────────────────────────

class Report {
  final String id;

  /// Student who submitted the report.
  final String studentId;
  final String studentName;
  final String? studentPhotoUrl;

  /// Subject / category.
  final ReportSubject subject;

  /// Custom subject title — used when subject == [ReportSubject.other].
  final String? customSubject;

  /// Priority level (defaults from subject but can be overridden by admin).
  final ReportPriority priority;

  /// Free‑text description by the student.
  final String description;

  /// Current lifecycle status.
  final ReportStatus status;

  /// Optional admin response once the report is treated.
  final String? adminResponse;
  final String? resolvedByAdminId;
  final String? resolvedByAdminName;
  final DateTime? resolvedAt;

  // ── Metadata ──
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUrl,
    required this.subject,
    this.customSubject,
    required this.priority,
    required this.description,
    required this.status,
    this.adminResponse,
    this.resolvedByAdminId,
    this.resolvedByAdminName,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Serialisation ──

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      studentPhotoUrl: map['studentPhotoUrl'] as String?,
      subject: ReportSubject.from(map['subject'] as String),
      customSubject: map['customSubject'] as String?,
      priority: ReportPriority.from(map['priority'] as String),
      description: map['description'] as String,
      status: ReportStatus.from(map['status'] as String),
      adminResponse: map['adminResponse'] as String?,
      resolvedByAdminId: map['resolvedByAdminId'] as String?,
      resolvedByAdminName: map['resolvedByAdminName'] as String?,
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhotoUrl': studentPhotoUrl,
      'subject': subject.value,
      'customSubject': customSubject,
      'priority': priority.value,
      'description': description,
      'status': status.value,
      'adminResponse': adminResponse,
      'resolvedByAdminId': resolvedByAdminId,
      'resolvedByAdminName': resolvedByAdminName,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentPhotoUrl,
    ReportSubject? subject,
    String? customSubject,
    ReportPriority? priority,
    String? description,
    ReportStatus? status,
    String? adminResponse,
    String? resolvedByAdminId,
    String? resolvedByAdminName,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
      subject: subject ?? this.subject,
      customSubject: customSubject ?? this.customSubject,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      resolvedByAdminId: resolvedByAdminId ?? this.resolvedByAdminId,
      resolvedByAdminName: resolvedByAdminName ?? this.resolvedByAdminName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Display title — returns custom subject when type is [ReportSubject.other].
  String displayTitle(String languageCode) {
    if (subject == ReportSubject.other &&
        customSubject != null &&
        customSubject!.isNotEmpty) {
      return customSubject!;
    }
    return subject.label(languageCode);
  }

  @override
  String toString() =>
      'Report(id: $id, subject: ${subject.value}, status: ${status.value}, '
      'priority: ${priority.value}, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Report && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

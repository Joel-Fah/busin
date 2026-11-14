/// The columns each query reads, named once. Apps never select `*`, so a column
/// added to a table later is not sent to every device until a screen needs it.
class Columns {
  const Columns._();

  static const profile =
      'id, school_id, email, full_name, avatar_url, phone, role, status, matricule, department, program, department_id, program_id, created_at, updated_at, streak_opt_in, payment_preference';
  static const faculty = 'id, name, code';
  static const department = 'id, faculty_id, name, code';
  static const program = 'id, name';
  static const installment = 'id, subscription_id, seq, percent, amount_xaf, due_date, status, proof_path, review_note';
  static const installmentReceipt = 'id, subscription_id, seq, proof_path, sent_at, decision, note, decided_at';
  static const subscriptionEvent = 'id, subscription_id, action, note, created_at';
  static const school = 'id, name, short_name, timezone, status, logo_path, city, country, website, contact_email, phone, about, billing_period, price_xaf, installment_plan, currency';
  static const stop = 'id, school_id, name, location, photo_path, active';
  static const semester = 'id, school_id, name, year, start_date, end_date';
  static const subscription =
      'id, school_id, student_id, semester_id, stop_id, status, proof_path, review_note, reviewed_by, reviewed_at, created_at, updated_at, payment_mode, period_start, period_end, billing_period, amount_xaf, installment_plan';
  static const bus = 'id, school_id, plate, name, capacity, in_service';
  static const trip = 'id, school_id, bus_id, driver_id, assistant_id, origin, created_by, direction, status, scheduled_start, started_at, ended_at, started_by';
  static const scan =
      'id, school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m';
  static const livePosition =
      'bus_id, school_id, trip_id, location, speed_mps, heading_deg, accuracy_m, source, recorded_at';
}

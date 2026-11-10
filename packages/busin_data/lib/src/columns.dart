/// The columns each query reads, named once. Apps never select `*`, so a column
/// added to a table later is not sent to every device until a screen needs it.
class Columns {
  const Columns._();

  static const profile =
      'id, school_id, email, full_name, avatar_url, phone, role, status, matricule, department, program, department_id, program_id, created_at, updated_at';
  static const faculty = 'id, name, code';
  static const department = 'id, faculty_id, name, code';
  static const program = 'id, name';
  static const subscriptionEvent = 'id, subscription_id, action, note, created_at';
  static const school = 'id, name, short_name, timezone, status, logo_path, city, country, website, contact_email, phone, about';
  static const stop = 'id, school_id, name, location, photo_path, active';
  static const semester = 'id, school_id, name, year, start_date, end_date';
  static const subscription =
      'id, school_id, student_id, semester_id, stop_id, status, proof_path, review_note, reviewed_by, reviewed_at, created_at, updated_at';
  static const bus = 'id, school_id, plate, name, capacity, in_service';
  static const trip = 'id, school_id, bus_id, driver_id, direction, status, scheduled_start, started_at, ended_at';
  static const scan =
      'id, school_id, trip_id, student_id, subscription_id, stop_id, scanned_by, scanned_at, location, accuracy_m';
  static const livePosition =
      'bus_id, school_id, trip_id, location, speed_mps, heading_deg, accuracy_m, source, recorded_at';
}

/// The letters shown in an avatar when there is no picture. Two words give the first letters of
/// each; one word gives its first two letters; with no name the email is used; with neither, "?".
/// Matches the admin portal, so the same person gets the same letters everywhere.
String initialsOf(String? fullName, [String? email]) {
  final name = (fullName ?? '').trim();
  final source = name.isNotEmpty ? name : (email ?? '').trim();
  if (source.isEmpty) return '?';
  final words = source.split(RegExp(r'[\s@._-]+')).where((w) => w.isNotEmpty).toList();
  if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
  final word = words.isEmpty ? source : words.first;
  return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
}

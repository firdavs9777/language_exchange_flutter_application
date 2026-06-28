/// CEFR ↔ TOPIK level mapping used by the Vocabulary level picker when the
/// active exam is Korean (TOPIK). Approximate but widely accepted mapping
/// (Cambridge CEFR / National Institute of Korean Language conversion).
const Map<String, String> _cefrToTopik = {
  'A1': 'TOPIK 1',
  'A2': 'TOPIK 2',
  'B1': 'TOPIK 3',
  'B2': 'TOPIK 4',
  'C1': 'TOPIK 5',
  'C2': 'TOPIK 6',
};

/// Returns the TOPIK label for a CEFR level, or null when the exam isn't
/// Korean (only TOPIK uses the dual label).
String? topikLabelFor(String cefrLevel, {required String examName}) {
  if (examName.toUpperCase() != 'TOPIK') return null;
  return _cefrToTopik[cefrLevel];
}

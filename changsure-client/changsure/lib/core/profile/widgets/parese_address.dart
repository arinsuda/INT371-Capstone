class ParsedThaiAddress {
  final String houseNumber;
  final String? village;
  final String? moo;
  final String? soi;
  final String? road;

  ParsedThaiAddress({
    required this.houseNumber,
    this.village,
    this.moo,
    this.soi,
    this.road,
  });

  Map<String, dynamic> toApiMap() {
    final m = <String, dynamic>{'house_number': houseNumber};
    void putOpt(String key, String? v) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) m[key] = t;
    }

    putOpt('village', village);
    putOpt('moo', moo);
    putOpt('soi', soi);
    putOpt('road', road);
    return m;
  }

  @override
  String toString() {
    return 'ParsedThaiAddress(houseNumber: $houseNumber, village: $village, moo: $moo, soi: $soi, road: $road)';
  }
}

ParsedThaiAddress parseThaiCombinedAddress(String input) {
  final raw = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (raw.isEmpty) {
    return ParsedThaiAddress(houseNumber: '');
  }

  // Normalize abbreviations
  String s = raw;
  s = s.replaceAll(RegExp(r'\bซ\.\s*'), 'ซอย ');
  s = s.replaceAll(RegExp(r'\bถ\.\s*'), 'ถนน ');
  s = s.replaceAll(RegExp(r'\bม\.\s*'), 'หมู่ ');

  // Parse หมู่ (moo): support "หมู่ 2" or "ม.2"
  String? moo;
  final mooMatch = RegExp(r'(?:หมู่)\s*([0-9]+)').firstMatch(s);
  if (mooMatch != null) {
    moo = mooMatch.group(1);
  }

  // Parse ซอย (soi): support various formats
  String? soi;
  final soiMatch = RegExp(
    r'(?:ซอย)\s*([^\s,]+(?:\s+[^\s,]+)*)(?=\s*(?:ถนน|หมู่|$|,))',
    caseSensitive: true,
  ).firstMatch(s);
  if (soiMatch != null) {
    soi = soiMatch.group(1)?.trim();
  }

  // Parse ถนน (road): capture until next keyword or end
  String? road;
  final roadMatch = RegExp(
    r'(?:ถนน)\s*([^\s,]+(?:\s+[^\s,]+)*)(?=\s*(?:หมู่บ้าน|หมู่|ซอย|$|,))',
  ).firstMatch(s);
  if (roadMatch != null) {
    road = roadMatch.group(1)?.trim();
  }

  // Parse หมู่บ้าน/อาคาร/คอนโด (village/building/condo)
  String? village;
  final villageMatch = RegExp(
    r'(?:หมู่บ้าน|อาคาร|คอนโด|คอนโดมิเนียม)\s*([^\s,]+(?:\s+[^\s,]+)*)(?=\s*(?:หมู่|ซอย|ถนน|$|,))',
  ).firstMatch(s);

  if (villageMatch != null) {
    final keyword = s.substring(
      villageMatch.start,
      villageMatch.start +
          (s.substring(villageMatch.start).indexOf(' ') > 0
              ? s.substring(villageMatch.start).indexOf(' ')
              : villageMatch.group(0)!.indexOf(' ')),
    );
    final name = villageMatch.group(1)?.trim();
    if (name != null && name.isNotEmpty) {
      // Capture the full keyword + name
      final fullMatch = RegExp(
        r'(หมู่บ้าน|อาคาร|คอนโด|คอนโดมิเนียม)\s*([^\s,]+(?:\s+[^\s,]+)*)',
      ).firstMatch(s.substring(villageMatch.start));
      if (fullMatch != null) {
        village = fullMatch.group(0)?.trim();
      }
    }
  }

  // Extract house number: everything before the first keyword
  final firstKeywordMatch = RegExp(
    r'\b(หมู่บ้าน|อาคาร|คอนโด|คอนโดมิเนียม|หมู่|ซอย|ถนน)\b',
  ).firstMatch(s);

  String houseNumber;
  if (firstKeywordMatch == null || firstKeywordMatch.start <= 0) {
    // No keywords found, entire string is house number
    houseNumber = s;
  } else {
    houseNumber = s.substring(0, firstKeywordMatch.start).trim();
  }

  // Clean up house number: remove trailing commas/spaces
  houseNumber = houseNumber.replaceAll(RegExp(r'[,\s]+$'), '');

  return ParsedThaiAddress(
    houseNumber: houseNumber.isNotEmpty ? houseNumber : s,
    village: village,
    moo: moo,
    soi: soi,
    road: road,
  );
}

// Example usage and tests
void main() {
  final testCases = [
    '123/45 หมู่บ้านสวนสยาม ซอย 5 ถนนพระราม 9',
    '99 ม.3 ซอยรามคำแหง 24 ถนนรามคำแหง',
    '456 อาคารไทยสมบูรณ์ ถนนสีลม',
    '78/9 หมู่ 2',
    '333',
    '12/34 ซ.พัฒนาการ 20 ถ.พัฒนาการ',
  ];

  for (final test in testCases) {
    print('\nInput: $test');
    print(parseThaiCombinedAddress(test));
  }
}

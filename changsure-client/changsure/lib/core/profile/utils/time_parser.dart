class TimeParser {
  static DateTime parse(dynamic value) {
    if (value == null) return DateTime.now();

    final dt = DateTime.parse(value.toString());

    if (dt.isUtc) return dt.toLocal();

    return dt;
  }

  static DateTime? parseNullable(dynamic value) {
    if (value == null) return null;
    return parse(value);
  }
}

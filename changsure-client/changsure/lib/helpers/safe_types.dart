/// =======================================
/// Safe Type Helpers + Error Debugging
/// =======================================

int safeInt(dynamic v, {String field = "unknown"}) {
  try {
    if (v == null) {
      print("❌ NULL received for int field: $field → default=0");
      return 0;
    }

    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;

    print("⚠️ Unexpected type for int field '$field': ${v.runtimeType}");
    return 0;
  } catch (e) {
    print("❌ Exception in safeInt for field='$field': $e");
    return 0;
  }
}

double safeDouble(dynamic v, {String field = "unknown"}) {
  try {
    if (v == null) {
      print("❌ NULL received for double field: $field → default=null");
      return 0.0;
    }

    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;

    print("⚠️ Unexpected type for double field '$field': ${v.runtimeType}");
    return 0.0;
  } catch (e) {
    print("❌ Exception in safeDouble for field='$field': $e");
    return 0.0;
  }
}

String safeString(dynamic v, {String field = "unknown"}) {
  try {
    if (v == null) {
      print("❌ NULL received for string field: $field → default='' ");
      return "";
    }

    return v.toString();
  } catch (e) {
    print("❌ Exception in safeString for field='$field': $e");
    return "";
  }
}

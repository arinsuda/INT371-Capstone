import 'package:changsure/models/services/service.dart';
import 'package:changsure/mockDB/service_categories.dart';

SubServiceDetail convertToSubServiceDetail(ServiceModel m) {
  return SubServiceDetail(
    id: m.id,
    name: m.serName,
    category: m.categoryName ?? "",
    image: m.imageUrls.isNotEmpty
        ? m.imageUrls.first
        : "assets/image/clean3.png",
    price: _parsePrice(m),
    subDetails: m.serDetails.isNotEmpty ? m.serDetails.join(", ") : "",
    description: m.serDescription ?? "",
    conditions: m.additionalTerms.isNotEmpty
        ? m.additionalTerms.map((e) => "- $e").join("\n")
        : "",
    duration: "", // 👈 เพิ่มเพื่อกัน error
  );
}

double _parsePrice(ServiceModel m) {
  final p = m.defaultPrice;
  if (p == null) return 0;

  if (p["type"] == "range") {
    return double.tryParse("${p["min"]}") ?? 0;
  }

  if (p["type"] == "fixed") {
    return double.tryParse("${p["value"]}") ?? 0;
  }

  return 0;
}

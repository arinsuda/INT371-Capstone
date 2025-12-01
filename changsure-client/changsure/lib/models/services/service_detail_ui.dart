import 'package:changsure/models/services/service.dart';

class ServiceDetailUI {
  final int id;
  final String name;
  final String category;
  final String image;
  final String description;
  final String subDetails;
  final String conditions;
  final String price;

  ServiceDetailUI({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.description,
    required this.subDetails,
    required this.conditions,
    required this.price,
  });

  factory ServiceDetailUI.fromServiceModel(ServiceModel m) {
    return ServiceDetailUI(
      id: m.id,
      name: m.serName,
      category: m.categoryName ?? "-",
      image: m.imageUrls.isNotEmpty
          ? m.imageUrls.first
          : "assets/image/clean3.png",
      description: (m.serDescription ?? "").isEmpty ? "-" : m.serDescription!,
      subDetails: m.serDetails.isNotEmpty ? m.serDetails.join(", ") : "-",
      conditions: m.additionalTerms.isNotEmpty
          ? m.additionalTerms.map((e) => "- $e").join("\n")
          : "-",
      price: _parsePrice(m),
    );
  }

  static String _parsePrice(ServiceModel m) {
    final p = m.defaultPrice;
    if (p == null) return "0";

    final type = p["type"];

    if (type == "fixed") {
      final v = p["value"];
      return v == null ? "0" : "$v";
    }

    if (type == "range") {
      final min = p["min"];
      final max = p["max"];

      if (min != null && max != null) return "$min - $max";
      if (min != null) return "$min";
      if (max != null) return "$max";
      return "0";
    }

    return "0";
  }
}

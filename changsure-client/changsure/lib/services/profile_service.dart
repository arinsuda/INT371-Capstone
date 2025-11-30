import 'dart:io';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/customers/customer_profile.dart';
import '../models/customers/update_customer_request.dart';
import '../models/technicians/technician_profile.dart';
import '../models/technicians/update_technician_request.dart';

class ProfileService {
  final ApiClient api;

  ProfileService(this.api);

  Future<CustomerProfile> getCustomerProfile() async {
    final response = await api.dio.get("/customers/profile");
    return CustomerProfile.fromJson(response.data['data']);
  }

  Future<TechnicianProfile> getTechnicianProfile() async {
    final response = await api.dio.get("/technicians/profile");
    return TechnicianProfile.fromJson(response.data['data']);
  }

  Future<void> updateCustomerProfile(UpdateCustomerRequest req) async {
    await api.dio.patch("/customers/profile", data: req.toJson());
  }

  Future<void> updateTechnicianProfile(TechnicianProfileRequest req) async {
    await api.dio.patch("/technicians/profile", data: req.toJson());
  }

  Future<void> updateTechnicianProvinces(List<int> provinceIds) async {
    await api.dio.patch(
      "/technicians/provinces",
      data: {"province_ids": provinceIds},
    );
  }

  Future<String> uploadTechnicianAvatar(String filePath) async {
    final fileName = filePath.split('/').last;

    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final res = await api.dio.post(
      "/technicians/profile/avatar",
      data: formData,
      options: Options(contentType: "multipart/form-data"),
    );

    if (res.statusCode == 200 && res.data["success"] == true) {
      return res.data["data"]["avatar_url"] as String;
    } else {
      throw Exception("อัปโหลดรูปโปรไฟล์ไม่สำเร็จ");
    }
  }

  Future<void> updateTechnicianAvatarURL(String avatarUrl) async {
    await api.dio.patch(
      "/technicians/profile",
      data: {"avatar_url": avatarUrl},
    );
  }
}

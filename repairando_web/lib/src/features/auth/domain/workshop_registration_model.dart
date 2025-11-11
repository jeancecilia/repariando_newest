import 'package:flutter/services.dart';

class WorkshopRegistrationModel {
  String? userId;
  Uint8List? profileImage;
  String? workshopName;
  String? shortDescription;
  String? phoneNumber;
  String? email;
  Uint8List? legalDocument;
  String? street;
  String? number;
  String? postalCode;
  String? city;
  String? companyName;
  String? commercialRegisterNumber;
  String? registerCourt;
  String? vatId;
  String? lat;
  String? lng;

  WorkshopRegistrationModel({
    this.userId,
    this.profileImage,
    this.workshopName,
    this.shortDescription,
    this.phoneNumber,
    this.email,
    this.legalDocument,
    this.street,
    this.number,
    this.postalCode,
    this.city,
    this.companyName,
    this.commercialRegisterNumber,
    this.registerCourt,
    this.vatId,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'workshop_name': workshopName,
      'short_description': shortDescription,
      'phone_number': phoneNumber,
      'email': email,
      'street': street,
      'number': number,
      'postal_code': postalCode,
      'city': city,
      'company_name': companyName,
      'commercial_registration_number': commercialRegisterNumber,
      'register_court': registerCourt,
      'vat_id': vatId,
      'userId': userId,
      'legal_document': legalDocument,
      'profile_image': profileImage,
      'lat': lat,
      'lng': lng,
    };
  }
}

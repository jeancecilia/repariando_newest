import 'dart:typed_data';

class WorkshopSettingModel {
  final String? userId;
  final String? profileImageUrl;
  final String? workshopName;
  final String? shortDescription;
  final String? phoneNumber;
  final String? email;
  final String? legalDocumentUrl;
  final String? street;
  final String? number;
  final String? postalCode;
  final String? city;
  final String? companyName;
  final String? commercialRegisterNumber;
  final String? registerCourt;
  final String? vatId;
  final String? bookingsOpen;

  WorkshopSettingModel({
    this.userId,
    this.profileImageUrl,
    this.workshopName,
    this.shortDescription,
    this.phoneNumber,
    this.email,
    this.legalDocumentUrl,
    this.street,
    this.number,
    this.postalCode,
    this.city,
    this.companyName,
    this.commercialRegisterNumber,
    this.registerCourt,
    this.vatId,
    this.bookingsOpen,
  });

  factory WorkshopSettingModel.fromJson(Map<String, dynamic> json) {
    return WorkshopSettingModel(
      userId: json['userId'] as String?,
      profileImageUrl: json['profile_image'] as String?,
      workshopName: json['workshop_name'] as String?,
      shortDescription: json['short_description'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      legalDocumentUrl: json['legal_document'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      postalCode: json['postal_code'] as String?,
      city: json['city'] as String?,
      companyName: json['company_name'] as String?,
      commercialRegisterNumber:
          json['commercial_registration_number'] as String?,
      registerCourt: json['register_court'] as String?,
      vatId: json['vat_id'] as String?,
      bookingsOpen: json['bookings_open'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profile_image': profileImageUrl,
      'workshop_name': workshopName,
      'short_description': shortDescription,
      'phone_number': phoneNumber,
      'email': email,
      'legal_document': legalDocumentUrl,
      'street': street,
      'number': number,
      'postal_code': postalCode,
      'city': city,
      'company_name': companyName,
      'commercial_registration_number': commercialRegisterNumber,
      'register_court': registerCourt,
      'vat_id': vatId,
      'bookings_open': bookingsOpen,
    };
  }

  // Create a copy with updated values
  WorkshopSettingModel copyWith({
    String? userId,
    String? profileImageUrl,
    String? workshopName,
    String? shortDescription,
    String? phoneNumber,
    String? email,
    String? legalDocumentUrl,
    String? street,
    String? number,
    String? postalCode,
    String? city,
    String? companyName,
    String? commercialRegisterNumber,
    String? registerCourt,
    String? vatId,
    String? bookingsOpen,
  }) {
    return WorkshopSettingModel(
      userId: userId ?? this.userId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      workshopName: workshopName ?? this.workshopName,
      shortDescription: shortDescription ?? this.shortDescription,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      legalDocumentUrl: legalDocumentUrl ?? this.legalDocumentUrl,
      street: street ?? this.street,
      number: number ?? this.number,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      companyName: companyName ?? this.companyName,
      commercialRegisterNumber:
          commercialRegisterNumber ?? this.commercialRegisterNumber,
      registerCourt: registerCourt ?? this.registerCourt,
      vatId: vatId ?? this.vatId,
      bookingsOpen: bookingsOpen ?? this.bookingsOpen,
    );
  }
}

// Model for handling updates with file uploads
class WorkshopUpdateModel {
  final String? workshopName;
  final String? shortDescription;
  final String? phoneNumber;
  final String? email;
  final String? street;
  final String? number;
  final String? postalCode;
  final String? city;
  final String? companyName;
  final String? commercialRegisterNumber;
  final String? registerCourt;
  final String? vatId;
  final String? bookingsOpen;
  final Uint8List? profileImage; // New image data
  final Uint8List? legalDocument; // New document data

  WorkshopUpdateModel({
    this.workshopName,
    this.shortDescription,
    this.phoneNumber,
    this.email,
    this.street,
    this.number,
    this.postalCode,
    this.city,
    this.companyName,
    this.commercialRegisterNumber,
    this.registerCourt,
    this.vatId,
    this.profileImage,
    this.legalDocument,
    this.bookingsOpen,
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
      "bookings_open": bookingsOpen,
    };
  }
}

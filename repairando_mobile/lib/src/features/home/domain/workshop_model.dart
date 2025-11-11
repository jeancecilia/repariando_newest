class WorkshopModel {
  final String? id;
  final String? userId;
  final String? profileImageUrl;
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
  final String? legalDocumentUrl;
  final DateTime? createdAt;
  final String? lat;
  final String? lng;
  final String? bookingOpen;

  WorkshopModel({
    this.id,
    this.userId,
    this.profileImageUrl,
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
    this.legalDocumentUrl,
    this.createdAt,
    this.lat,
    this.lng,
    this.bookingOpen,
  });

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    return WorkshopModel(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      profileImageUrl: json['profile_image'] as String?,
      workshopName: json['workshop_name'] as String?,
      shortDescription: json['short_description'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      street: json['street'] as String?,
      lat: json['lat'] as String?,
      lng: json['lng'] as String?,
      number: json['number'] as String?,
      postalCode: json['postal_code'] as String?,
      city: json['city'] as String?,
      companyName: json['company_name'] as String?,
      commercialRegisterNumber:
          json['commercial_registration_number'] as String?,
      registerCourt: json['register_court'] as String?,
      vatId: json['vat_id'] as String?,
      legalDocumentUrl: json['legal_document'] as String?,
      bookingOpen: json['bookings_open'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'profile_iamge': profileImageUrl,
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
      'legal_document': legalDocumentUrl,
      'bookings_open': bookingOpen,
      'created_at': createdAt?.toIso8601String(),
      'lat': lat,
      'lng': lng,
    };
  }
}

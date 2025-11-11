class CustomerModel {
  final String? id;
  final String name;
  final String surname;
  final String email;
  final String? profileImage;

  CustomerModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.profileImage,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profile_image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? '',
      'name': name,
      'surname': surname,
      'email': email,
      'profile_image': profileImage ?? '',
    };
  }
}

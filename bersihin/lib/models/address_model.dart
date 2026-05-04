class AddressModel {
  final String id;
  final String username;
  final String address;
  final String lat;
  final String lng;
  final String houseType;
  final String description;

  AddressModel({
    required this.id,
    required this.username,
    required this.address,
    required this.lat,
    required this.lng,
    required this.houseType,
    required this.description,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      address: json['address'] ?? '',
      lat: json['lat']?.toString() ?? '0',
      lng: json['lng']?.toString() ?? '0',
      houseType: json['house_type'] ?? 'Rumah / Townhouse',
      description: json['description'] ?? '',
    );
  }
}

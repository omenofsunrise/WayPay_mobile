class UpdateClientRequest {
  final String fullName;
  final String phone;
  final String birthdate;
  final String? registrationAddress;

  UpdateClientRequest({
    required this.fullName,
    required this.phone,
    required this.birthdate,
    this.registrationAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'birthdate': birthdate,
      'registrationAddress': registrationAddress,
    };
  }
}

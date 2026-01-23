class School {
  final String id;
  final String name;
  final String location;
  final String? phone;
  final String? email;

  School({
    required this.id,
    required this.name,
    required this.location,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'phone': phone,
    'email': email,
  };
}

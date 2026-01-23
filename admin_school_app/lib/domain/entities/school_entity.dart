class SchoolEntity {
  final String? id;
  final String name;
  final String? location;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final int? establishedYear;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolEntity({
    this.id,
    required this.name,
    this.location,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.establishedYear,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });
}
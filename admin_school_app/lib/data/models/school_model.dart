import '../../domain/entities/school_entity.dart';

class SchoolModel extends SchoolEntity {
  SchoolModel({
    super.id,
    required super.name,
    super.location,
    super.phone,
    super.email,
    super.website,
    super.logoUrl,
    super.establishedYear,
    super.isActive = true,
    super.createdAt,
    super.updatedAt,
  });

  static String? _asString(dynamic v) {
    if (v == null) return null;
    try {
      return v.toString();
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString(),
      name: (json['name'] ?? '').toString(),
      location: _asString(json['location']),
      phone: _asString(json['phone']),
      email: _asString(json['email']),
      website: _asString(json['website']),
      logoUrl: _asString(json['logo_url']),
      establishedYear: json['established_year'] is int
          ? json['established_year'] as int
          : int.tryParse(json['established_year']?.toString() ?? ''),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (location != null) 'location': location,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (establishedYear != null) 'established_year': establishedYear,
      'is_active': isActive,
    };
  }
}
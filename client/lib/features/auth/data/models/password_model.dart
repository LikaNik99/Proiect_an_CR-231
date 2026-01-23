import '../../domain/entities/password_entity.dart';

class PasswordModel extends PasswordEntity {
  PasswordModel({
    required super.email,
    super.code,
    super.password,
  });

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    return PasswordModel(
      email: json['email'],
      code: json['code'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (code != null) 'code': code,
      if (password != null) 'password': password,
    };
  }
}

class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String currencyCode;
  final String themePreference;
  final bool biometricEnabled;
  final bool emailVerified;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.currencyCode,
    required this.themePreference,
    required this.biometricEnabled,
    required this.emailVerified,
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? currencyCode,
    String? themePreference,
    bool? biometricEnabled,
    bool? emailVerified,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      themePreference: themePreference ?? this.themePreference,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

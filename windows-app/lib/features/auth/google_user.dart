/// Signed-in Google account profile.
class GoogleUser {
  const GoogleUser({
    required this.id,
    required this.email,
    this.name,
    this.pictureUrl,
  });

  final String id;
  final String email;
  final String? name;
  final String? pictureUrl;

  String get displayName => name?.isNotEmpty == true ? name! : email;

  /// First letter for avatar fallback.
  String get initial {
    final src = name?.isNotEmpty == true ? name! : email;
    return src.isEmpty ? '?' : src.substring(0, 1).toUpperCase();
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'pictureUrl': pictureUrl,
      };

  factory GoogleUser.fromJson(Map<String, Object?> j) => GoogleUser(
        id: j['id'] as String? ?? '',
        email: j['email'] as String? ?? '',
        name: j['name'] as String?,
        pictureUrl: j['pictureUrl'] as String?,
      );
}

class Location {
  final String name;
  final List<String> roles;

  const Location({
    required this.name,
    required this.roles,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] as String,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'roles': roles,
      };
}

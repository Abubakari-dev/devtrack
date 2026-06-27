class Client {
  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String location;
  final int projectCount;
  final int completedCount;

  const Client({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.location,
    this.projectCount = 0,
    this.completedCount = 0,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name.substring(0, name.length > 1 ? 2 : 1).toUpperCase() : '??';
  }
}

// lib/models/app_user.dart

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String displayName;
  final bool isLocked;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.isLocked,
  });

  // Factory constructor để tạo đối tượng từ Firestore Document
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user', // Mặc định là 'user'
      displayName: data['displayName'] ?? 'N/A',
      isLocked: data['isLocked'] ?? false,
    );
  }
}
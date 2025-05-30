import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // e.g., 'owner', 'admin', 'sublider', 'recruta'
  final String? clanId; // ID of the clan the user belongs to
  final Timestamp createdAt;
  // Add other fields as needed: status (online/offline), lastSeen, etc.

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.clanId,
    required this.createdAt,
  });

  // Factory constructor to create a UserModel from Firestore data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'recruta', // Default role
      clanId: json['clanId'] as String?,
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(), // Handle potential null
    );
  }

  // Method to convert UserModel instance to a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'clanId': clanId,
      'createdAt': createdAt,
    };
  }
}


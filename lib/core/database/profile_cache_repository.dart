import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ProfileCache {
  final String uid;
  final String? displayName;
  final String? email;
  final String? phone;
  final Uint8List? avatarData;
  final DateTime? lastSynced;

  const ProfileCache({
    required this.uid,
    this.displayName,
    this.email,
    this.phone,
    this.avatarData,
    this.lastSynced,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'avatar_data': avatarData,
      'last_synced': lastSynced?.toIso8601String(),
    };
  }

  factory ProfileCache.fromMap(Map<String, dynamic> map) {
    return ProfileCache(
      uid: map['uid'] as String,
      displayName: map['display_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      avatarData: map['avatar_data'] as Uint8List?,
      lastSynced: map['last_synced'] != null 
          ? DateTime.parse(map['last_synced'] as String)
          : null,
    );
  }
}

class ProfileCacheRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  // ── SAVE PROFILE CACHE ──────────────────────────────────────────────────────
  Future<void> saveProfile(ProfileCache profile) async {
    final db = await _dbService.database;
    
    await db.insert(
      'profile_cache',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── GET PROFILE CACHE ───────────────────────────────────────────────────────
  Future<ProfileCache?> getProfile(String uid) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'profile_cache',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ProfileCache.fromMap(maps.first);
  }

  // ── UPDATE AVATAR ───────────────────────────────────────────────────────────
  Future<void> updateAvatar(String uid, Uint8List avatarData) async {
    final db = await _dbService.database;
    
    await db.update(
      'profile_cache',
      {
        'avatar_data': avatarData,
        'last_synced': DateTime.now().toIso8601String(),
      },
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // ── DELETE PROFILE CACHE ────────────────────────────────────────────────────
  Future<void> deleteProfile(String uid) async {
    final db = await _dbService.database;
    await db.delete(
      'profile_cache',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }
}

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Read-only owner path for the currently authenticated account.
/// A child uses a separate Firebase Auth UID but all learning data stays
/// under users/{parentUid}/children/{childId}.
class AuthIdentity {
  static String? _parentUid;
  static String? _childId;
  static String? familyCode;
  static const _storage = FlutterSecureStorage();
  static const _familyKey = 'lexia_remembered_family_code';
  static const _profilesKey = 'lexia_remembered_family_profiles';

  static Future<void> rememberFamilyCode(String code) async {
    familyCode = code;
    await _storage.write(key: _familyKey, value: code);
  }

  static Future<void> rememberProfiles(List<Map<String, dynamic>> profiles) async {
    await _storage.write(key: _profilesKey, value: jsonEncode(profiles));
  }

  static Future<List<Map<String, dynamic>>> storedProfiles(String code) async {
    if (await storedFamilyCode() != code) return [];
    final raw = await _storage.read(key: _profilesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((p) => Map<String, dynamic>.from(p as Map)).toList();
    } catch (_) { return []; }
  }

  static Future<String?> storedFamilyCode() async {
    final code = familyCode ?? await _storage.read(key: _familyKey);
    if (code != null && code.isNotEmpty) familyCode = code;
    return code;
  }

  static Future<void> forgetFamilyCode() async {
    familyCode = null;
    await _storage.delete(key: _familyKey);
    await _storage.delete(key: _profilesKey);
  }

  static Future<List<Map<String, dynamic>>> loadFamilyProfiles(String code) async {
    final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
        .httpsCallable('verifyFamilyCode')
        .call<Map<String, dynamic>>({'familyCode': code});
    return (result.data['profiles'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }


  static String get parentUid => _parentUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  static String? get childId => _childId;

  static Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _parentUid = null;
      _childId = null;
      return;
    }
    final claims = (await user.getIdTokenResult()).claims ?? {};
    _parentUid = claims['role'] == 'child' && claims['parentUid'] is String
        ? claims['parentUid'] as String : user.uid;
    _childId = claims['role'] == 'child' && claims['childId'] is String
        ? claims['childId'] as String : null;
  }

  static void configureChild(String parentUid, String childId) {
    _parentUid = parentUid;
    _childId = childId;
  }

  static void clearChild() { _parentUid = null; _childId = null; }
}

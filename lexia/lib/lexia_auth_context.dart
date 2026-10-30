import 'package:firebase_auth/firebase_auth.dart';

/// Resolves the Firestore owner of a child profile.
/// Parent users own the Firestore document; child users have their own Auth UID.
class LexiaAuthContext {
  static String? _parentUid;
  static String? _childId;

  static String get parentUid =>
      _parentUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  static String? get childId => _childId;

  static void setChild({required String parentUid, required String childId}) {
    _parentUid = parentUid;
    _childId = childId;
  }

  static void clear() {
    _parentUid = null;
    _childId = null;
  }

  static Future<void> restore() async {
    final user = FirebaseAuth.instance.currentUser;
    clear();
    if (user == null) return;
    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? {};
    if (claims['role'] == 'child' &&
        claims['parentUid'] is String &&
        claims['childId'] is String) {
      setChild(parentUid: claims['parentUid'] as String,
          childId: claims['childId'] as String);
    }
  }
}

/// In-memory navigation state. Never persisted or logged.
class ChildLoginFlow {
  static String? familyCode;
  static List<Map<String, String>> profiles = [];

  static void clear() {
    familyCode = null;
    profiles = [];
  }
}

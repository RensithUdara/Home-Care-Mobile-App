import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_care/models/household.dart';

class HouseholdService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _households =>
      _db.collection('households');
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static Future<List<Household>> householdsFor(String uid) async {
    final snap = await _households.where('memberIds', arrayContains: uid).get();
    final households = snap.docs
        .map((doc) => Household.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return households;
  }

  static Future<Household> ensurePersonalHousehold({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    await _users.doc(uid).set({
      'email': normalizeEmail(email),
      if (displayName != null && displayName.trim().isNotEmpty)
        'name': displayName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await acceptPendingInvites(uid: uid, email: email);

    final existing = await householdsFor(uid);
    if (existing.isNotEmpty) return existing.first;

    final name = displayName == null || displayName.trim().isEmpty
        ? 'My Home'
        : '${displayName.trim()}\'s Home';
    final doc = await _households.add({
      'name': name,
      'ownerUid': uid,
      'memberIds': [uid],
      'inviteEmails': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Household(
      id: doc.id,
      name: name,
      ownerUid: uid,
      memberIds: [uid],
    );
  }

  static Future<List<Household>> acceptPendingInvites({
    required String uid,
    required String email,
  }) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return const [];
    final invites = await _households
        .where('inviteEmails', arrayContains: normalized)
        .get();
    if (invites.docs.isEmpty) return const [];

    final batch = _db.batch();
    for (final doc in invites.docs) {
      batch.update(doc.reference, {
        'memberIds': FieldValue.arrayUnion([uid]),
        'inviteEmails': FieldValue.arrayRemove([normalized]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return invites.docs
        .map((doc) => Household.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<Household> renameHousehold({
    required Household household,
    required String name,
  }) async {
    final clean = name.trim().isEmpty ? 'My Home' : name.trim();
    await _households.doc(household.id).update({
      'name': clean,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Household(
      id: household.id,
      name: clean,
      ownerUid: household.ownerUid,
      memberIds: household.memberIds,
      inviteEmails: household.inviteEmails,
    );
  }

  static Future<Household> inviteByEmail({
    required Household household,
    required String email,
  }) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw Exception('Enter a valid email address');
    }

    final userSnap =
        await _users.where('email', isEqualTo: normalized).limit(1).get();
    final newMemberUid = userSnap.docs.isEmpty ? null : userSnap.docs.first.id;

    final updates = <String, Object>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newMemberUid != null) {
      updates['memberIds'] = FieldValue.arrayUnion([newMemberUid]);
      updates['inviteEmails'] = FieldValue.arrayRemove([normalized]);
    } else {
      updates['inviteEmails'] = FieldValue.arrayUnion([normalized]);
    }
    await _households.doc(household.id).update(updates);

    final doc = await _households.doc(household.id).get();
    return Household.fromMap(doc.data()!, doc.id);
  }

  static Future<void> leaveHousehold(Household household, String uid) async {
    if (household.ownerUid == uid) {
      throw Exception('The household owner cannot leave their own home');
    }
    await _households.doc(household.id).update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> syncCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await ensurePersonalHousehold(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }
}

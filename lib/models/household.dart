import 'package:cloud_firestore/cloud_firestore.dart';

class Household {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberIds;
  final List<String> inviteEmails;

  const Household({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberIds,
    this.inviteEmails = const [],
  });

  bool isOwner(String uid) => ownerUid == uid;

  factory Household.fromMap(Map<String, dynamic> map, String id) => Household(
        id: id,
        name: (map['name'] as String?)?.trim().isNotEmpty == true
            ? (map['name'] as String).trim()
            : 'My Home',
        ownerUid: map['ownerUid'] as String? ?? '',
        memberIds: (map['memberIds'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        inviteEmails: (map['inviteEmails'] as List? ?? const [])
            .whereType<String>()
            .map((e) => e.toLowerCase())
            .toList(),
      );

  Map<String, dynamic> toJSON() => {
        'name': name,
        'ownerUid': ownerUid,
        'memberIds': memberIds,
        'inviteEmails': inviteEmails,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

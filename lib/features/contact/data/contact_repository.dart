import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../domain/contact.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ContactRepository(isar);
});

class ContactRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  ContactRepository(this._isar);

  /// Watch all active contacts sorted by name
  Stream<List<Contact>> watchActiveContacts() {
    return _isar.contacts
        .filter()
        .isActiveEqualTo(true)
        .sortByName()
        .watch(fireImmediately: true);
  }

  /// Get active contacts asynchronously
  Future<List<Contact>> getActiveContacts() async {
    return await _isar.contacts
        .filter()
        .isActiveEqualTo(true)
        .sortByName()
        .findAll();
  }

  /// Find contact by syncId
  Future<Contact?> getContactBySyncId(String syncId) async {
    return await _isar.contacts
        .filter()
        .syncIdEqualTo(syncId)
        .findFirst();
  }

  /// Create new contact
  Future<Contact> createContact({
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    final now = DateTime.now();
    final contact = Contact()
      ..syncId = _uuid.v4()
      ..name = name.trim()
      ..phoneNumber = phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim()
      ..email = email?.trim().isEmpty == true ? null : email?.trim()
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.contacts.put(contact);
    });

    return contact;
  }

  /// Update existing contact
  Future<Contact> updateContact({
    required int id,
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    final contact = await _isar.contacts.get(id);
    if (contact == null) {
      throw Exception('Kontak tidak ditemukan.');
    }

    contact.name = name.trim();
    contact.phoneNumber = phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim();
    contact.email = email?.trim().isEmpty == true ? null : email?.trim();
    contact.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.contacts.put(contact);
    });

    return contact;
  }

  /// Soft delete contact (sets isActive = false)
  Future<void> softDeleteContact(int id) async {
    final contact = await _isar.contacts.get(id);
    if (contact == null) {
      throw Exception('Kontak tidak ditemukan.');
    }

    contact.isActive = false;
    contact.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.contacts.put(contact);
    });
  }
}

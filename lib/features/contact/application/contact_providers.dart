import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contact_repository.dart';
import '../domain/contact.dart';

final activeContactsStreamProvider = StreamProvider<List<Contact>>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.watchActiveContacts();
});

class ContactController extends StateNotifier<AsyncValue<void>> {
  final ContactRepository _repo;

  ContactController(this._repo) : super(const AsyncValue.data(null));

  Future<Contact?> addContact({
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    try {
      final contact = await _repo.createContact(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
      );
      state = const AsyncValue.data(null);
      return contact;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateContact({
    required int id,
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateContact(
        id: id,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteContact(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.softDeleteContact(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final contactControllerProvider = StateNotifierProvider<ContactController, AsyncValue<void>>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return ContactController(repo);
});

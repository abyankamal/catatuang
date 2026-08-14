import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../application/contact_providers.dart';
import '../domain/contact.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  final Contact? existingContact;

  const ContactFormScreen({super.key, this.existingContact});

  static Future<Contact?> showAsBottomSheet(
    BuildContext context, {
    Contact? existingContact,
  }) {
    return showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ContactFormScreen(existingContact: existingContact),
      ),
    );
  }

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  bool get isEditMode => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingContact?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingContact?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.existingContact?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();

      Contact? resultContact;
      if (isEditMode) {
        final success = await ref.read(contactControllerProvider.notifier).updateContact(
              id: widget.existingContact!.id,
              name: name,
              phoneNumber: phone,
              email: email,
            );
        if (success) {
          resultContact = widget.existingContact!
            ..name = name
            ..phoneNumber = phone
            ..email = email;
        }
      } else {
        resultContact = await ref.read(contactControllerProvider.notifier).addContact(
              name: name,
              phoneNumber: phone,
              email: email,
            );
      }

      if (mounted) {
        if (resultContact != null) {
          Navigator.of(context).pop(resultContact);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode ? 'Kontak berhasil diperbarui!' : 'Kontak baru berhasil ditambahkan!',
              ),
              backgroundColor: AppColors.income,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan kontak. Coba lagi.'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditMode ? 'Edit Kontak' : 'Tambah Kontak Baru',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nama Kontak
                _buildLabel('Nama Lengkap *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Budi Santoso',
                    hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.neutral,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama kontak wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nomor Telepon
                _buildLabel('Nomor WhatsApp / Telepon (Opsional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 08123456789',
                    hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.neutral,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                _buildLabel('Email (Opsional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Contoh: budi@gmail.com',
                    hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.neutral,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            isEditMode ? 'Simpan Perubahan' : 'Tambah Kontak',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
    );
  }
}

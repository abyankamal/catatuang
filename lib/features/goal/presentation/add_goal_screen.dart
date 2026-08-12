import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../application/goal_providers.dart';

import '../../wallet/domain/wallet.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  final Wallet? existingGoal;

  const AddGoalScreen({super.key, this.existingGoal});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  DateTime? _selectedDate;

  bool _isLoading = false;
  bool get isEditMode => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingGoal?.name);
    
    final target = widget.existingGoal?.targetAmount;
    _targetController = TextEditingController(
      text: target != null ? target.toInt().toString() : '',
    );
    _selectedDate = widget.existingGoal?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final targetAmount = double.tryParse(_targetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    try {
      if (isEditMode) {
        await ref.read(goalControllerProvider.notifier).updateGoal(
          id: widget.existingGoal!.id,
          name: name,
          targetAmount: targetAmount,
          targetDate: _selectedDate,
        );
      } else {
        await ref.read(goalControllerProvider.notifier).addGoal(
          name: name,
          targetAmount: targetAmount,
          targetDate: _selectedDate,
        );
      }
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Tujuan "$name" berhasil diperbarui!'
                  : 'Tujuan "$name" berhasil ditambahkan!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditMode ? 'Edit Tujuan' : 'Tambah Tujuan',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai nabung untuk impianmu!',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tentukan target dan batas waktu tabungan ini.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildLabel('Nama Tujuan'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        hint: 'Contoh: Beli MacBook Pro',
                        icon: Icons.track_changes_rounded,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    _buildLabel('Nominal Target (Rp)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: 'Contoh: 20000000',
                        icon: Icons.payments_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        final numValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (numValue == null || numValue <= 0) return 'Nominal tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    _buildLabel('Tenggat Waktu (Opsional)'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.neutral,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate != null 
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Pilih Tanggal',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 15,
                                  color: _selectedDate != null ? AppColors.secondary : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              InkWell(
                                onTap: () => setState(() => _selectedDate = null),
                                child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
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
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEditMode ? 'Simpan Perubahan' : 'Buat Tujuan',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.neutral,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}

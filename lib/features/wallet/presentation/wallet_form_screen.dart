import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../application/wallet_controller.dart';
import '../domain/wallet.dart';

class WalletFormScreen extends ConsumerStatefulWidget {
  final Wallet? existingWallet;

  const WalletFormScreen({super.key, this.existingWallet});

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;

  bool get isEditMode => widget.existingWallet != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingWallet?.name);
    
    final balance = widget.existingWallet?.balance ?? 0.0;
    _balanceController = TextEditingController(
      text: isEditMode ? balance.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    // Pada mode edit, saldo awal tidak dikirim karena diubah lewat transaksi.
    // Pada mode buat, jika kosong anggap 0.
    final initialBalance = double.tryParse(_balanceController.text.replaceAll('.', '')) ?? 0.0;

    final controller = ref.read(walletControllerProvider.notifier);

    bool success;
    if (isEditMode) {
      success = await controller.updateWallet(
        id: widget.existingWallet!.id,
        name: name,
      );
    } else {
      success = await controller.createWallet(
        name: name,
        initialBalance: initialBalance,
      );
    }

    if (success && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(walletControllerProvider).error?.toString() ?? 'Gagal menyimpan dompet',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(walletControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditMode ? 'Edit Dompet' : 'Tambah Dompet',
          style: GoogleFonts.outfit(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Dompet',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Nama Dompet
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Contoh: BCA, Gopay, Uang Tunai',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama dompet tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Saldo Awal
              TextFormField(
                controller: _balanceController,
                enabled: !isEditMode, // Disabled saat edit
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isEditMode ? 'Saldo Saat Ini' : 'Saldo Awal (Opsional)',
                  helperText: isEditMode 
                      ? 'Saldo hanya bisa diubah melalui transaksi.'
                      : 'Masukkan saldo awal saat ini jika ada.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  prefixText: 'Rp ',
                ),
              ),
            ],
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
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Simpan Dompet',
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
}

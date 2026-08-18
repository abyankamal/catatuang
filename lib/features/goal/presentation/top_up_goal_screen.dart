import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../wallet/domain/wallet.dart';
import '../application/goal_providers.dart';

class TopUpGoalScreen extends ConsumerStatefulWidget {
  final String goalId;
  const TopUpGoalScreen({super.key, required this.goalId});

  @override
  ConsumerState<TopUpGoalScreen> createState() => _TopUpGoalScreenState();
}

class _TopUpGoalScreenState extends ConsumerState<TopUpGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Wallet? _selectedWallet;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet sumber dana terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    try {
      await ref.read(goalControllerProvider.notifier).topUpGoal(
        goalWalletSyncId: widget.goalId,
        sourceWalletSyncId: _selectedWallet!.syncId,
        amount: amount,
        date: DateTime.now(),
      );
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menabung!')),
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
    // Note: To show regular wallets we need a provider, or we can just fetch it from WalletRepository
    final activeGoals = ref.watch(activeGoalsStreamProvider).valueOrNull ?? [];
    final goal = activeGoals.cast<Wallet?>().firstWhere(
          (g) => g?.syncId == widget.goalId,
          orElse: () => null,
        );

    final goalName = goal?.name ?? 'Tujuan Tabungan';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Nabung',
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
                      'Tabung untuk $goalName',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uang yang ditabung akan dipindahkan ke kantong virtual ini.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildLabel('Nominal (Rp)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 50000',
                        hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        final numValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (numValue == null || numValue <= 0) return 'Nominal tidak valid';
                        
                        if (_selectedWallet != null && numValue > _selectedWallet!.balance) {
                          return 'Saldo tidak cukup';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    _buildLabel('Sumber Dana'),
                    const SizedBox(height: 8),
                    // For now, we will fetch wallets manually via a button to a dialog
                    InkWell(
                      onTap: () => _showWalletPicker(context),
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
                            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedWallet != null 
                                    ? '${_selectedWallet!.name} (${CurrencyFormatter.format(_selectedWallet!.balance)})'
                                    : 'Pilih Kantong',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 15,
                                  color: _selectedWallet != null ? AppColors.secondary : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    SizedBox(
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
                              'Nabung Sekarang',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                  ],
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

  void _showWalletPicker(BuildContext context) {
    // A simple dialog to select the wallet. We will use activeWalletsStreamProvider if it exists,
    // otherwise we can fetch manually. Let's assume we can fetch it from WalletRepository synchronously.
    // However, it's better to use Consumer and a BottomSheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final activeWallets = ref.watch(activeRegularWalletsStreamProvider);
            return activeWallets.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada kantong')),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.neutral,
                        child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                      ),
                      title: Text(wallet.name, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      subtitle: Text('Saldo: ${CurrencyFormatter.format(wallet.balance)}'),
                      onTap: () {
                        setState(() {
                          _selectedWallet = wallet;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Gagal memuat: $err')),
            );
          },
        );
      },
    );
  }
}

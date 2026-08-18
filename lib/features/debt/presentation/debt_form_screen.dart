import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../contact/application/contact_providers.dart';
import '../../contact/presentation/contact_form_screen.dart';
import '../application/debt_providers.dart';
import '../domain/debt.dart';

class DebtFormScreen extends ConsumerStatefulWidget {
  final Debt? existingDebt;
  final String initialType; // 'PAYABLE' or 'RECEIVABLE'

  const DebtFormScreen({
    super.key,
    this.existingDebt,
    this.initialType = 'PAYABLE',
  });

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _startDate;
  DateTime? _dueDate;

  String? _selectedContactSyncId;
  String? _selectedWalletSyncId;
  bool _affectWallet = true;
  bool _isLoading = false;

  bool get isEditMode => widget.existingDebt != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingDebt != null) {
      final d = widget.existingDebt!;
      _selectedType = d.type;
      _titleController = TextEditingController(text: d.title);
      _amountController = TextEditingController(
        text: d.totalAmount.toInt() == d.totalAmount
            ? d.totalAmount.toInt().toString()
            : d.totalAmount.toString(),
      );
      _notesController = TextEditingController(text: d.notes ?? '');
      _startDate = d.startDate;
      _dueDate = d.dueDate;
      _selectedContactSyncId = d.contactSyncId;
      _affectWallet = false; // By default false for editing existing debt
    } else {
      _selectedType = widget.initialType;
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _notesController = TextEditingController();
      _startDate = DateTime.now();
      _dueDate = null;
      _affectWallet = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Mulai Pinjaman',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectDueDate() async {
    final initial = _dueDate ?? _startDate.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Pilih Tanggal Jatuh Tempo',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _openAddContactModal() async {
    final newContact = await ContactFormScreen.showAsBottomSheet(context);
    if (newContact != null && mounted) {
      setState(() {
        _selectedContactSyncId = newContact.syncId;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedContactSyncId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kontak terlebih dahulu.')),
      );
      return;
    }

    if (!isEditMode && _affectWallet && _selectedWalletSyncId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih dompet yang terpengaruh.')),
      );
      return;
    }

    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;
      if (isEditMode) {
        success = await ref.read(debtControllerProvider.notifier).updateDebt(
              id: widget.existingDebt!.id,
              title: _titleController.text.trim(),
              totalAmount: amount,
              dueDate: _dueDate,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
      } else {
        success = await ref.read(debtControllerProvider.notifier).createDebt(
              type: _selectedType,
              contactSyncId: _selectedContactSyncId!,
              title: _titleController.text.trim(),
              totalAmount: amount,
              startDate: _startDate,
              dueDate: _dueDate,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              walletSyncId: _affectWallet ? _selectedWalletSyncId : null,
              affectWallet: _affectWallet,
            );
      }

      if (mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Catatan berhasil diperbarui!'
                    : (_selectedType == 'PAYABLE'
                        ? 'Catatan Utang berhasil disimpan!'
                        : 'Catatan Piutang berhasil disimpan!'),
              ),
              backgroundColor: _selectedType == 'PAYABLE' ? AppColors.expense : AppColors.income,
            ),
          );
        } else {
          final error = ref.read(debtControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan: ${error ?? "Terjadi kesalahan"}'),
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
    final contactsAsync = ref.watch(activeContactsStreamProvider);
    final walletsAsync = ref.watch(activeRegularWalletsStreamProvider);
    final isPayable = _selectedType == 'PAYABLE';
    final themeColor = isPayable ? AppColors.expense : AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditMode
              ? 'Edit Catatan'
              : (isPayable ? 'Catat Utang Baru' : 'Catat Piutang Baru'),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Toggle (Utang vs Piutang)
                    if (!isEditMode) ...[
                      _buildTypeToggle(),
                      const SizedBox(height: 24),
                    ],

                    // Title / Keperluan
                    _buildLabel('Judul / Keperluan *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isPayable
                            ? 'Contoh: Pinjaman modal usaha / Sewa kontrakan'
                            : 'Contoh: Talangan tiket konser / Pinjam beli buku',
                        hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.description_outlined, color: themeColor),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Judul / Keperluan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Contact Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel(isPayable ? 'Pemberi Pinjaman *' : 'Peminjam / Pihak Terkait *'),
                        TextButton.icon(
                          onPressed: _openAddContactModal,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                          label: Text(
                            '+ Kontak Baru',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    contactsAsync.when(
                      data: (contacts) {
                        if (contacts.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.neutral,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Belum ada kontak.'),
                                ElevatedButton(
                                  onPressed: _openAddContactModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Tambah Kontak', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }

                        // Auto-select first contact if none selected
                        _selectedContactSyncId ??= contacts.first.syncId;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.neutral,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedContactSyncId,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: contacts.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c.syncId,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded,
                                          size: 18, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(
                                        c.name,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (c.phoneNumber != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${c.phoneNumber})',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedContactSyncId = val);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Gagal memuat kontak: $e'),
                    ),
                    const SizedBox(height: 20),

                    // Total Nominal Input
                    _buildLabel('Total Nominal (Rp) *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Nominal wajib diisi';
                        final num = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (num == null || num <= 0) return 'Nominal tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Tanggal Mulai & Jatuh Tempo
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tanggal Mulai *'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectStartDate,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 16, color: themeColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateFormatter.formatShortDate(_startDate),
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Jatuh Tempo (Opsional)'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectDueDate,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_available_rounded,
                                          size: 16,
                                          color: _dueDate != null ? AppColors.primary : Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _dueDate != null
                                              ? DateFormatter.formatShortDate(_dueDate!)
                                              : 'Pilih Tanggal',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _dueDate != null
                                                ? AppColors.secondary
                                                : Colors.grey.shade500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_dueDate != null)
                                        GestureDetector(
                                          onTap: () => setState(() => _dueDate = null),
                                          child: const Icon(Icons.clear_rounded, size: 16, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Opsi Pengaruhi Saldo Dompet (Hanya saat create baru)
                    if (!isEditMode) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.neutral,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengaruhi Saldo Dompet?',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPayable
                                            ? 'Tambah saldo dompet (Uang pinjaman masuk)'
                                            : 'Kurangi saldo dompet (Uang dipinjamkan keluar)',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _affectWallet,
                                  activeTrackColor: themeColor,
                                  activeThumbColor: Colors.white,
                                  onChanged: (val) => setState(() => _affectWallet = val),
                                ),
                              ],
                            ),

                            if (_affectWallet) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _buildLabel('Pilih Dompet Terkait'),
                              const SizedBox(height: 8),
                              walletsAsync.when(
                                data: (wallets) {
                                  if (wallets.isEmpty) {
                                    return const Text('Belum ada dompet aktif.');
                                  }
                                  _selectedWalletSyncId ??= wallets.first.syncId;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedWalletSyncId,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                        items: wallets.map((w) {
                                          return DropdownMenuItem<String>(
                                            value: w.syncId,
                                            child: Row(
                                              children: [
                                                const Icon(Icons.account_balance_wallet_rounded,
                                                    size: 16, color: AppColors.primary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  w.name,
                                                  style: GoogleFonts.hankenGrotesk(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  CurrencyFormatter.format(w.balance),
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedWalletSyncId = val);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text('Gagal memuat dompet: $e'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Notes / Catatan
                    _buildLabel('Catatan Tambahan (Opsional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Rencana dicicil 2x setiap akhir bulan',
                        hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
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
                                isEditMode
                                    ? 'Simpan Perubahan'
                                    : (isPayable ? 'Simpan Catatan Utang' : 'Simpan Catatan Piutang'),
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedType = 'PAYABLE');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'PAYABLE' ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Utang (Saya Meminjam)',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == 'PAYABLE' ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedType = 'RECEIVABLE');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'RECEIVABLE' ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Piutang (Saya Meminjamkan)',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == 'RECEIVABLE' ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

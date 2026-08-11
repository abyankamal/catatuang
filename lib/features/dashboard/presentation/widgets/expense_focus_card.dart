import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ExpenseFocusCard extends StatelessWidget {
  final double monthlyExpense;

  const ExpenseFocusCard({
    super.key,
    this.monthlyExpense = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = monthlyExpense == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fokus Pengeluaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          if (isEmpty)
            _buildEmptyState()
          else
            _buildChartData(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 14,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      color: Colors.grey.shade300,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BELUM ADA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Belum ada data pengeluaran bulan ini.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartData() {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dual Circular Arc Painter
                CustomPaint(
                  size: const Size(170, 170),
                  painter: _FocusRingPainter(
                    primaryProgress: 0.68,
                    tertiaryProgress: 0.35,
                    primaryColor: AppColors.primary,
                    tertiaryColor: AppColors.tertiary,
                  ),
                ),

                // Center Label
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MINGGUAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '68%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Legend Items
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Tempat Tinggal', AppColors.primary),
            _buildLegendItem('Makanan', AppColors.tertiary),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double primaryProgress;
  final double tertiaryProgress;
  final Color primaryColor;
  final Color tertiaryColor;

  _FocusRingPainter({
    required this.primaryProgress,
    required this.tertiaryProgress,
    required this.primaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;

    // Background Ring
    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, (size.width - strokeWidth) / 2, bgPaint);

    // Primary Arc (Outer)
    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: (size.width - strokeWidth) / 2);
    const startAngle = -pi / 2;

    canvas.drawArc(
      rect,
      startAngle,
      2 * pi * primaryProgress,
      false,
      primaryPaint,
    );

    // Inner Tertiary Arc
    const innerStrokeWidth = 10.0;
    final innerRect = Rect.fromCircle(center: center, radius: (size.width - strokeWidth) / 2 - 12);
    final tertiaryPaint = Paint()
      ..color = tertiaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      innerRect,
      startAngle + (2 * pi * 0.2),
      2 * pi * tertiaryProgress,
      false,
      tertiaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

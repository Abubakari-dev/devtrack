import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/project_service.dart';
import '../../projects/models/project_model.dart';
import '../widgets/export_widgets.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final service = ProjectService(uid: user.uid);
      final projects = await service.getProjectsStream().first;
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExportingCsv = true);
    try {
      final csv = _buildCsv();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'devtrack_financials_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      if (!mounted) return;
      _showSuccessSheet(fileName, file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  void _showSuccessSheet(String fileName, String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 64),
            const SizedBox(height: 16),
            Text('Export Successful', style: AppTextStyles.headlineMedium(context)),
            const SizedBox(height: 8),
            Text(
              'Your file "$fileName" is ready.',
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Dismiss', style: AppTextStyles.titleLarge(context).copyWith(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Open File', style: AppTextStyles.titleLarge(context).copyWith(fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _buildCsv() {
    final b = StringBuffer();
    b.writeln('project_id,project_name,total_price,advance,remaining,status,progress');
    for (final p in _projects) {
      b.writeln([
        _esc(p.id),
        _esc(p.name),
        p.totalPrice.toStringAsFixed(2),
        p.advanceAmount.toStringAsFixed(2),
        p.remainingAmount.toStringAsFixed(2),
        _esc(p.statusLabel),
        '${(p.progressPercent * 100).round()}%',
      ].join(','));
    }
    return b.toString();
  }

  String _esc(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalRevenue = _projects.fold(0.0, (sum, p) => sum + p.totalPrice);
    final totalCollected = _projects.fold(0.0, (sum, p) => sum + p.advanceAmount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Export & Reports', style: AppTextStyles.titleLarge(context)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          const SectionLabel('QUICK SUMMARY'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ExportStatTile(
                  label: 'Revenue',
                  value: 'TSh ${(totalRevenue / 1000).toStringAsFixed(1)}k',
                  icon: Icons.payments_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExportStatTile(
                  label: 'Collected',
                  value: 'TSh ${(totalCollected / 1000).toStringAsFixed(1)}k',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel('EXPORT OPTIONS'),
          const SizedBox(height: 12),
          ExportOptionCard(
            title: 'Financial Summary (CSV)',
            description: 'A spreadsheet compatible file with all project pricing and payment status.',
            icon: Icons.grid_on_rounded,
            color: AppColors.blue,
            isLoading: _isExportingCsv,
            onTap: _isExportingCsv ? () {} : _exportCsv,
          ),
          ExportOptionCard(
            title: 'Detailed Project Report (PDF)',
            description: 'A professional PDF document including milestones, tasks, and project health.',
            icon: Icons.picture_as_pdf_rounded,
            color: AppColors.purple,
            isLoading: _isExportingPdf,
            onTap: () {
              setState(() => _isExportingPdf = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _isExportingPdf = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF Generation coming soon!')),
                );
              });
            },
          ),
          const SizedBox(height: 24),
          const SectionLabel('DATA PRIVACY'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exported files are stored locally on your device. Ensure you handle data securely when sharing these files.',
                    style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.amber, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/app_database.dart';
import '../database/attachment_repository.dart';
import '../database/profile_cache_repository.dart';
import '../database/payment_receipt_repository.dart';
import '../../features/projects/data/project_repository.dart';
import '../../features/projects/data/activity_log_repository.dart';
import '../../features/projects/data/notes_repository.dart';
import '../../features/projects/models/models.dart';
import '../../features/finance/data/finance_repository.dart';

class DataSyncService {
  // ─── CACHED REPOSITORY ACCESS (SINGLETON) ───────────────────────────────
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  AppDatabase? _db;
  void setDatabase(AppDatabase db) => _db = db;

  final ProjectRepository projectRepo = ProjectRepository();
  final ActivityLogRepository activityLogRepo = ActivityLogRepository();
  final NotesRepository notesRepo = NotesRepository();
  final AttachmentRepository attachmentRepo = AttachmentRepository();
  final ProfileCacheRepository profileCacheRepo = ProfileCacheRepository();
  final PaymentReceiptRepository receiptRepo = PaymentReceiptRepository();
  final FinanceRepository financeCloudRepo = FinanceRepository();

  final Connectivity _connectivity = Connectivity();

  // ─── FORCE SYNC LOGIC ──────────────────────────────────────────────────
  
  /// Performs a full synchronization of local data to Firebase.
  /// This ensures that any offline changes are pushed to the cloud.
  Future<void> syncAllData() async {
    if (_db == null) return;
    final db = _db!;

    await _safeExecute(() async {
      // 1. Sync Wallets
      final wallets = await db.select(db.wallets).get();
      for (final w in wallets) {
        await financeCloudRepo.saveWallet({
          'id': w.id,
          'name': w.name,
          'type': w.type,
          'provider': w.provider,
          'accountNumber': w.accountNumber,
          'balance': w.balance,
          'currency': w.currency,
          'icon': w.icon,
          'color': w.color,
        });
      }

      // 1b. Sync Categories
      final categories = await db.select(db.categories).get();
      for (final cat in categories) {
        await _safeExecute(() async {
          await FirebaseFirestore.instance.collection('categories').doc(cat.id).set({
            'id': cat.id,
            'name': cat.name,
            'type': cat.type,
            'icon': cat.icon,
            'color': cat.color,
            'parentId': cat.parentId,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }, 'SyncCategory_${cat.id}');
      }

      // 2. Sync Transactions
      final transactions = await db.select(db.transactions).get();
      for (final t in transactions) {
        await financeCloudRepo.saveTransaction({
          'id': t.id,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'amount': t.amount,
          'type': t.type,
          'walletId': t.walletId,
          'note': t.note,
          'date': t.date.toIso8601String(),
          'projectId': t.projectId,
          'categoryId': t.categoryId,
        });
      }

      // 3. Sync Debts
      final debts = await db.select(db.debts).get();
      for (final d in debts) {
        await financeCloudRepo.saveDebt({
          'id': d.id,
          'contactName': d.contactName,
          'contactReference': d.contactReference,
          'type': d.type,
          'principalAmount': d.principalAmount,
          'amountPaid': d.amountPaid,
          'interestRate': d.interestRate,
          'dateGiven': d.dateGiven.toIso8601String(),
          'dueDate': d.dueDate?.toIso8601String(),
          'status': d.status,
          'notes': d.notes,
          'walletId': d.walletId,
          'projectId': d.projectId,
        });
      }

      // 4. Sync Budgets
      final budgets = await db.select(db.budgets).get();
      for (final b in budgets) {
        await financeCloudRepo.saveBudget({
          'id': b.id,
          'name': b.name,
          'categoryId': b.categoryId,
          'period': b.period,
          'amount': b.amount,
          'rolloverEnabled': b.rolloverEnabled,
        });
      }

      // 5. Sync Transfers
      final transfers = await db.select(db.transfers).get();
      for (final tr in transfers) {
        await financeCloudRepo.saveTransfer({
          'id': tr.id,
          'fromWalletId': tr.fromWalletId,
          'toWalletId': tr.toWalletId,
          'amount': tr.amount,
          'fee': tr.fee,
          'date': tr.date.toIso8601String(),
          'note': tr.note,
        });
      }

      // 6. Sync Debt Payments
      final debtPayments = await db.select(db.debtPayments).get();
      for (final dp in debtPayments) {
        await financeCloudRepo.saveDebtPayment({
          'id': dp.id,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'debtId': dp.debtId,
          'amount': dp.amount,
          'date': dp.date.toIso8601String(),
          'walletId': dp.walletId,
          'projectId': dp.projectId,
        });
      }

      // 7. Sync Transaction Splits
      final splits = await db.select(db.transactionSplits).get();
      for (final s in splits) {
        await _safeExecute(() async {
          await FirebaseFirestore.instance.collection('transaction_splits').doc(s.id).set({
            'id': s.id,
            'transactionId': s.transactionId,
            'categoryId': s.categoryId,
            'amount': s.amount,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }, 'SyncSplit_${s.id}');
      }

      // 8. Sync Reminders
      final reminders = await db.select(db.reminders).get();
      for (final r in reminders) {
        await _safeExecute(() async {
          await FirebaseFirestore.instance.collection('reminders').doc(r.id).set({
            'id': r.id,
            'type': r.type,
            'relatedId': r.relatedId,
            'message': r.message,
            'scheduledDate': r.scheduledDate.toIso8601String(),
            'isRead': r.isRead,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }, 'SyncReminder_${r.id}');
      }
      
    }, 'SyncAllData');
  }

  // ─── AUTOMATIC ERROR RECOVERY HELPER ──────────────────────────────────
  Future<T> _safeExecute<T>(Future<T> Function() action, String errorLabel) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('DataSyncService Error [$errorLabel]: $e');
      // Here you could implement a retry mechanism or local queuing
      rethrow; 
    }
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  Future<void> createProjectWithLog(Project project, String userName) async {
    await _safeExecute(() async {
      await projectRepo.saveProject(project);
      // Specific detailed log for the service layer
      await activityLogRepo.logActivity(project.id, 'Project created', userName: userName);
    }, 'CreateProject');
  }

  Future<void> toggleSubtaskWithProgressUpdate({
    required String projectId,
    required String phaseId,
    required String taskId,
    required String subtaskId,
    required bool isDone,
    required String subtaskName,
  }) async {
    await _safeExecute(() async {
      await projectRepo.updateSubtaskStatus(
        projectId: projectId, 
        phaseId: phaseId, 
        taskId: taskId, 
        subtaskId: subtaskId, 
        isDone: isDone, 
        subtaskName: subtaskName
      );
    }, 'ToggleSubtask');
  }

  Future<void> attachFileToProject({
    required String projectId,
    String? phaseId,
    String? taskId,
    String? subtaskId,
    required String fileName,
    required String fileType,
    required Uint8List fileData,
    String? notes,
  }) async {
    await _safeExecute(() async {
      final attachment = AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: projectId,
        phaseId: phaseId,
        taskId: taskId,
        subtaskId: subtaskId,
        fileName: fileName,
        fileType: fileType,
        type: AttachmentType.file,
        fileData: fileData,
        fileSize: fileData.length,
        uploadedAt: DateTime.now(),
        notes: notes,
      );

      await attachmentRepo.saveAttachment(attachment);
      await activityLogRepo.logActivity(projectId, 'Attached file: $fileName');
    }, 'AttachFile');
  }

  Future<void> attachUrlToProject({
    required String projectId,
    String? phaseId,
    String? taskId,
    String? subtaskId,
    required String fileName,
    required String url,
    String? notes,
  }) async {
    await _safeExecute(() async {
      final attachment = AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: projectId,
        phaseId: phaseId,
        taskId: taskId,
        subtaskId: subtaskId,
        fileName: fileName,
        fileType: 'url',
        type: AttachmentType.link,
        fileUrl: url,
        fileSize: 0,
        uploadedAt: DateTime.now(),
        notes: notes,
      );

      await attachmentRepo.saveAttachment(attachment);
      await activityLogRepo.logActivity(projectId, 'Added link: $fileName');
    }, 'AttachUrl');
  }

  Future<void> saveProfileWithAvatar({
    required String uid,
    required String displayName,
    required String email,
    String? phone,
    Uint8List? avatarData,
  }) async {
    await _safeExecute(() async {
      final profile = ProfileCache(
        uid: uid,
        displayName: displayName,
        email: email,
        phone: phone,
        avatarData: avatarData,
        lastSynced: DateTime.now(),
      );

      await profileCacheRepo.saveProfile(profile);
    }, 'SaveProfile');
  }

  Future<String> getTotalStorageUsedFormatted() async {
    return await _safeExecute(() async {
      final bytes = await attachmentRepo.getTotalStorageUsed();
      return _formatBytes(bytes);
    }, 'GetStorageUsed');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

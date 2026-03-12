import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class PaymentReceipt {
  final String id;
  final String paymentId;
  final Uint8List receiptData;
  final DateTime uploadedAt;

  const PaymentReceipt({
    required this.id,
    required this.paymentId,
    required this.receiptData,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_id': paymentId,
      'receipt_data': receiptData,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory PaymentReceipt.fromMap(Map<String, dynamic> map) {
    return PaymentReceipt(
      id: map['id'] as String,
      paymentId: map['payment_id'] as String,
      receiptData: map['receipt_data'] as Uint8List,
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
    );
  }
}

class PaymentReceiptRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  // ── SAVE RECEIPT ────────────────────────────────────────────────────────────
  Future<void> saveReceipt(PaymentReceipt receipt) async {
    final db = await _dbService.database;
    
    await db.insert(
      'payment_receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── GET RECEIPT FOR PAYMENT ─────────────────────────────────────────────────
  Future<PaymentReceipt?> getReceiptForPayment(String paymentId) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_receipts',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PaymentReceipt.fromMap(maps.first);
  }

  // ── DELETE RECEIPT ──────────────────────────────────────────────────────────
  Future<void> deleteReceipt(String receiptId) async {
    final db = await _dbService.database;
    await db.delete(
      'payment_receipts',
      where: 'id = ?',
      whereArgs: [receiptId],
    );
  }

  // ── DELETE RECEIPT BY PAYMENT ID ────────────────────────────────────────────
  Future<void> deleteReceiptByPaymentId(String paymentId) async {
    final db = await _dbService.database;
    await db.delete(
      'payment_receipts',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
    );
  }
}

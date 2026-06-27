import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _hideBalancesKey = 'hide_balances_enabled';
  bool _isFinanceUnlocked = false;

  bool get isFinanceUnlocked => _isFinanceUnlocked;
  void unlockFinance() => _isFinanceUnlocked = true;
  void lockFinance() => _isFinanceUnlocked = false;

  Future<bool> get isHideBalancesEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideBalancesKey) ?? false;
  }

  Future<void> setHideBalancesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideBalancesKey, enabled);
  }


  Future<bool> get isBiometricAvailable async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> get isBiometricEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            deviceCredentialsRequiredTitle: 'Biometric required',
          ),
          IOSAuthMessages(
            cancelButton: 'No thanks',
          ),
        ],
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('SecurityService Error: $e');
      return false;
    }
  }
}

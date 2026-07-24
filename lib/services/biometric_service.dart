import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricKey = 'biometric_enabled';

  /// Check if the device has biometrics available
  Future<bool> isBiometricAvailable() async {
    final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Check if the user has enabled biometrics in settings
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  /// Set the user's preference for biometrics
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  /// Authenticate the user with biometrics
  Future<bool> authenticate(String reason) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }
}

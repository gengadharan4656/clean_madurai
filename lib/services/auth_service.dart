import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  String? _verificationId;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> sendOTP({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(String) onError,
  }) async {
    _setLoading(true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _createUserIfNeeded();
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _setLoading(false);
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> verifyOTP({
    required String otp,
    required String name,
    required String ward,
  }) async {
    if (_verificationId == null) return false;
    _setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      await _createUserIfNeeded(name: name, ward: ward, role: 'citizen');
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    String? expectedRole,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      final actualRole = (doc.data()?['role'] as String?) ?? 'citizen';
      if (expectedRole != null && expectedRole != actualRole) {
        await _auth.signOut();
        _error = expectedRole == 'collector'
            ? 'This account is not a garbage collector account.'
            : 'This account is not a citizen account.';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      await _createUserIfNeeded();
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String ward,
    String role = 'citizen',
    Map<String, dynamic>? extraDetails,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createUserIfNeeded(
        name: name,
        ward: ward,
        role: role,
        extraDetails: extraDetails,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> _createUserIfNeeded({
    String? name,
    String? ward,
    String role = 'citizen',
    Map<String, dynamic>? extraDetails,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'id': uid,
        'name': name ?? (role == 'collector' ? 'Garbage Collector' : 'Citizen'),
        'phone': _auth.currentUser?.phoneNumber ?? '',
        'email': _auth.currentUser?.email ?? '',
        'ward': ward ?? 'Ward 1',
        'role': role,
        'collectorDetails': extraDetails ?? {},
        'cleanlinessScore': 0,
        'totalComplaints': 0,
        'resolvedComplaints': 0,
        'badges': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

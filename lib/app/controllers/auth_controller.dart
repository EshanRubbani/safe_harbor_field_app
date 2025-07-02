import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;

  User? get firebaseUser => _firebaseUser.value;
  UserModel? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _firebaseUser.bindStream(_auth.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAllNamed(AppRoutes.LOGIN);
    } else {
      await _loadUserData(user);
      Get.offAllNamed(AppRoutes.HOME);
    }
  }

  Future<void> _loadUserData(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        _user.value = UserModel.fromJson(doc.data()!);
      } else {
        final userData = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          lastSignIn: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(user.uid).set(userData.toJson());
        _user.value = userData;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data: ${e.toString()}', snackPosition: SnackPosition.TOP,);
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    try {
      _isLoading.value = true;
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        
        final userData = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastSignIn: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData.toJson());

        Get.snackbar(
          'Success',
          'Account created successfully!',
 snackPosition: SnackPosition.TOP,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }
      Get.snackbar('Registration Error', message, snackPosition: SnackPosition.TOP,);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', snackPosition: SnackPosition.TOP,);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading.value = true;
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'lastSignIn': DateTime.now().millisecondsSinceEpoch});
      }

      Get.snackbar(
        'Success',
        'Logged in successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = e.message ?? 'Login failed';
      }
      Get.snackbar('Login Error', message, snackPosition: SnackPosition.TOP,);
    } catch (e) {
      // Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', snackPosition: SnackPosition.TOP,);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading.value = true;
      await _auth.signOut();
      _user.value = null;
      Get.snackbar(
        'Success',
        'Logged out successfully!',
       snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}', snackPosition: SnackPosition.TOP,);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Password reset email sent! Check your inbox.',
     snackPosition: SnackPosition.TOP,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = e.message ?? 'Failed to send reset email';
      }
      Get.snackbar('Reset Password Error', message, snackPosition: SnackPosition.TOP,);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', snackPosition: SnackPosition.TOP,);
    } finally {
      _isLoading.value = false;
    }
  }
}
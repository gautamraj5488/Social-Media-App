import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireStoreServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser(){
    return _auth.currentUser;
  }

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String uid,
  }) async {
    try {
      // Create a new user document in Firestore
      await _firestore.collection('users').doc(getCurrentUser()!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
        'uis':uid,
      });
      print("User created successfully");
    } catch (e) {
      print("Error creating user: $e");
    }
  }
}
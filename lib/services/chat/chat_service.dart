import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/services/firestore.dart';

import '../../utils/helpers/helper_fuctions.dart';
import 'models/message.dart';

class ChatService{

  final FirebaseFirestore _firestore =  FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FireStoreServices _fireStoreServices = FireStoreServices();

  Future<List<Map<String, dynamic>>> getUsersList() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching users list: $e');
      return []; // or throw an exception if desired
    }
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
// go through each individual user
        final user = doc.data();
// return user
        return user;
      }).toList();
    });
  }

  Stream<List<String>> getRequestToConfirmStream(String userId) {
    return _firestore.collection("users").doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('requestToConfirm') && data['requestToConfirm'] is List) {
          return List<String>.from(data['requestToConfirm']);
        }
      }
      return [];
    });
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    DocumentSnapshot userSnapshot = await _firestore.collection("users").doc(userId).get();
    if (userSnapshot.exists) {
      return userSnapshot.data() as Map<String, dynamic>?;
    }
    return null;
  }




  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    String msgId = "";
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      msgId: msgId,
    );


    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');
    // Use add() method to let Firestore generate the document ID
    DocumentReference newMessageRef = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    msgId = newMessageRef.id;

    await newMessageRef.update({'msgId': msgId});
    await _fireStoreServices.incrementUnreadMessageCount(receiverID);
  }


  Future<bool> deleteMessage(String chatRoomID, String messageId) async {
    try {
      // Reference to the message document with the given messageId
      DocumentReference messageDocRef = _firestore
          .collection("chat_rooms")
          .doc(chatRoomID)
          .collection("messages")
          .doc(messageId);

      // Check if the message document exists
      DocumentSnapshot messageDocSnapshot = await messageDocRef.get();
      if (messageDocSnapshot.exists) {
        // Delete the message document
        await messageDocRef.update({'message': ""});
        print("Message with msgId: $messageId deleted");
        return true;


        // You can show a snackbar or perform any other action here to notify the user
      } else {
        print("Message document not found with msgId: $messageId");
      }
    } catch (e) {
      print('Error deleting message: $e');
      // Handle error (e.g., display error message to user)
    }
    return false;
  }



  Stream<QuerySnapshot> getMessages (String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }



}
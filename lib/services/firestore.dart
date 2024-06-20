import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import '../features/authentication/screens/login/login.dart';


class FireStoreServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  User? getCurrentUser(){
    return _auth.currentUser;
  }

  Future<bool> isDeviceConnected() async{
    try{
      await canLaunchUrlString("google.com");
      return true;
    } catch(e){
      return false;
    }
  }

  Future<bool> isUsernameInUse(String username) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      print("Username Query Result: ${result.docs}");
      return result.docs.isNotEmpty;
    } catch (e) {
      print("Error checking username: $e");
      return false; // Return false in case of an error
    }
  }

  Future<bool> isEmailInUse(String email) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      print("Email Query Result: ${result.docs}");
      return result.docs.isNotEmpty;
    } catch (e) {
      print("Error checking email: $e");
      return false; // Return false in case of an error
    }
  }

  Future<List<DocumentSnapshot>> getSharedPosts(String userId) async {
    try {
      // Query shared_posts collection where sharedTo field is equal to userId
      QuerySnapshot querySnapshot = await _firestore
          .collection('shared_posts')
          .where('sharedTo', isEqualTo: userId)
          .get();

      // Return list of DocumentSnapshots
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching shared posts: $e');
      throw e; // Throw error to handle it in calling function
    }
  }


  Future<int> getUnreadMessageCount(String currentUser, String otherUser) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser).get();
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

    if (data['unreadMessages'] == null) {
      await _firestore.collection('users').doc(currentUser).update({'unreadMessages': {}});
      return 0;
    }

    Map<String, dynamic> unreadMessages = data['unreadMessages'] as Map<String, dynamic>;
    return unreadMessages[otherUser] ?? 0;
  }

  Future<void> incrementUnreadMessageCount(String receiverId) async {
    DocumentReference userRef = _firestore.collection('users').doc(receiverId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userRef);
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      Map<String, int> unreadMessages;
      if (data['unreadMessages'] == null) {
        unreadMessages = {};
      } else {
        unreadMessages = Map<String, int>.from(data['unreadMessages']);
      }

      unreadMessages[_auth.currentUser!.uid] = (unreadMessages[_auth.currentUser!.uid] ?? 0) + 1;
      transaction.update(userRef, {'unreadMessages': unreadMessages});
    });
  }

  Future<void> resetUnreadMessageCount(String currentUser, String senderId) async {
    DocumentReference userRef = _firestore.collection('users').doc(currentUser);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userRef);
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      Map<String, int> unreadMessages;
      if (data['unreadMessages'] == null) {
        unreadMessages = {};
      } else {
        unreadMessages = Map<String, int>.from(data['unreadMessages']);
      }

      unreadMessages[senderId] = 0;
      transaction.update(userRef, {'unreadMessages': unreadMessages});
    });
  }
  // logout(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Container(
  //         height: 200,
  //         width: double.infinity,
  //         decoration: BoxDecoration(
  //           //color: Colors.white,
  //             borderRadius: BorderRadius.only(topRight: Radius.circular(12),topLeft: Radius.circular(12))
  //         ),
  //
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: <Widget>[
  //             Text('Are you sure to Logout ?'),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     FirebaseAuth.instance.signOut();
  //                     Navigator.pop(context);
  //                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context)=> LoginScreen()), (route)=>false);
  //
  //                   },
  //                   child: Text('Yes'),
  //                 ),
  //                 OutlinedButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                   },
  //                   child: Text('Close'),
  //                 ),
  //               ],
  //             )
  //           ],
  //         ),
  //       );
  //     },
  //   );
  //   // FirebaseAuth.instance.signOut();
  //   // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context)=> LoginScreen()), (route)=>false);
  // }

  Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(uid) async {
    User? user = getCurrentUser();
    if (user != null) {
      return await _firestore.collection('users').doc(uid).get();
    } else {
      throw Exception("No user logged in");
    }
  }


  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String uid,
    required String FCMtoken,
    required String profilePicture,
    required List<String> following,
    required List<String> followers,
    required List<String> requested,
    required List<String> requestToConfirm,
  }) async {
      try {
        // Create a new user document in Firestore
        await _firestore.collection('users').doc(getCurrentUser()!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'profilePic': profilePicture,
          'phoneNumber': phoneNumber,
          'password': password,
          'createdAt': FieldValue.serverTimestamp(),
          'uis':uid,
          'FCMtoken':FCMtoken,
          'following': following,
          'followers': followers,
          'requested': requested,
          'requestToConfirm': requestToConfirm,
          'messageUpdatedAt': FieldValue.serverTimestamp(),
        });
        print("User created successfully");
      } catch (e) {
      print("Error creating user: $e");
    }
  }

  Future<void> updateUser({
    required String firstName,
    required String lastName,
    required String username,
    required String phoneNumber,
    required String password,
    required String uid,
  }) async {
    try {
      // Update an existing user document in Firestore
      await _firestore.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'phoneNumber': phoneNumber,
        'password': password,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User updated successfully");
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  Future<void> updateUserPasswordFromLogin({
    required String password,
    required String uid,
  }) async {
    try {
      // Update an existing user document in Firestore
      await _firestore.collection('users').doc(uid).update({
        'password': password,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User updated successfully");
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  Future<void> updateMessageTime({
    required String uid,
  }) async {
    try {
      // Update an existing user document in Firestore
      await _firestore.collection('users').doc(uid).update({
        'messageUpdatedAt': FieldValue.serverTimestamp(),
      });
      print("User updated successfully");
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  Future<void> updateFCMtoken({
    required String FCMtoken,
    required String uid,
  }) async {
    try {
      // Update an existing user document in Firestore
      await _firestore.collection('users').doc(uid).update({
        'FCMtoken': FCMtoken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User updated successfully");
    } catch (e) {
      print("Error updating user: $e");
    }
  }


  // AIzaSyAMcw6jDBdoKvCC265Wdde0BQ2dU5CzRzs
  Future<void> sendNotification(String serverKey, String recipientToken) async {
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/social-media-app-436b7/messages:send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    };

    final body = {
      'message': {
        'token': recipientToken,
        'notification': {
          'title': 'Friend Request',
          'body': 'You have received a friend request',
        },
      },
    };

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.reasonPhrase}');
    }
  }



  // Send a follow request
  Future<void> sendFollowRequest(String senderId, String recipientId) async {
    try {
      await _firestore.collection('users').doc(senderId).update({
        'requested': FieldValue.arrayUnion([recipientId]),
      });

      await _firestore.collection('users').doc(recipientId).update({
        'requestToConfirm': FieldValue.arrayUnion([senderId]),
      });
      print("Follow request sent successfully");
    } catch (e) {
      print("Error sending follow request: $e");
    }
  }

  Future<void> followBack(String currentUserId, String otherUserId) async {
    // Add the other user to the current user's following list
    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([otherUserId])
    });

    // Add the current user to the other user's followers list
    await _firestore.collection('users').doc(otherUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId])
    });
  }

// Approve a follow request
  Future<void> approveFollowRequest(String recipientId, String senderId) async {
    try {
      await _firestore.collection('users').doc(recipientId).update({
        'requestToConfirm': FieldValue.arrayRemove([senderId]),
      });

      await _firestore.collection('users').doc(recipientId).update({
        'followers': FieldValue.arrayUnion([senderId]),
      });

      await _firestore.collection('users').doc(senderId).update({
        'following': FieldValue.arrayUnion([recipientId]),
      });

      print("Follow request approved successfully");
    } catch (e) {
      print("Error approving follow request: $e");
    }
  }

// Unfollow a user
  Future<void> unfollowUser(String currentUserId, String userIdToUnfollow) async {
    try {
      // Remove userIdToUnfollow from the following list of the current user
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([userIdToUnfollow]),
      });

      // Remove currentUserId from the followers list of the unfollowed user
      await _firestore.collection('users').doc(userIdToUnfollow).update({
        'requested': FieldValue.arrayRemove([currentUserId]),
      });

      print("Successfully unfollowed user");
    } catch (e) {
      print("Error unfollowing user: $e");
    }
  }

// Unsend a follow request
  Future<void> unsendFollowRequest(String senderId, String recipientId) async {
    try {
      // Remove recipientId from the sender's requested list
      await _firestore.collection('users').doc(senderId).update({
        'requested': FieldValue.arrayRemove([recipientId]),
      });

      // Remove senderId from the recipient's requestToConfirm list
      await _firestore.collection('users').doc(recipientId).update({
        'requestToConfirm': FieldValue.arrayRemove([senderId]),
      });

      print("Follow request unsent successfully");
    } catch (e) {
      print("Error unsending follow request: $e");
    }
  }

  Future<bool> isCurrentUserRequested(String currentUserId, String otherUserId) async {
    try {
      // Get the document of the other user
      DocumentSnapshot otherUserSnapshot = await _firestore.collection('users').doc(otherUserId).get();

      // Check if the document exists and if it contains the 'requested' field
      if (otherUserSnapshot.exists) {
        print("Document exists");
        Map<String, dynamic>? userData = otherUserSnapshot.data() as Map<String, dynamic>?;

        if (userData != null) {
          print("User data retrieved: $userData");
          if (userData.containsKey('requestToConfirm')) {
            List<dynamic> requestedList = userData['requestToConfirm'] ?? [];
            print("Requested list: $requestedList");
            return requestedList.contains(currentUserId);
          } else {
            print("Requested field does not exist");
          }
        } else {
          print("User data is null");
        }
      } else {
        print("Document does not exist");
      }

      // Return false if the document doesn't exist or doesn't contain the 'requested' field
      return false;
    } catch (e) {
      print("Error checking if current user is requested: $e");
      return false;
    }
  }

  Future<bool> isFollowing(String currentUserId, String otherUserId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(currentUserId).get();
    List following = doc['following'];
    return following.contains(otherUserId);
  }
  Future<bool> isCurrentUserFriend(String currentUserId, String otherUserId) async {
    try {
      // Get the document of the other user
      DocumentSnapshot otherUserSnapshot = await _firestore.collection('users').doc(otherUserId).get();

      // Check if the document exists and if it contains the 'requested' field
      if (otherUserSnapshot.exists) {
        //print("Document exists");
        Map<String, dynamic>? userData = otherUserSnapshot.data() as Map<String, dynamic>?;

        if (userData != null) {
          print("User data retrieved: $userData");
          if (userData.containsKey('followers')) {
            List<dynamic> followerList = userData['followers'] ?? [];
            //print("Requested list: $followerList");
            return followerList.contains(currentUserId);
          } else {
            print("Requested field does not exist");
          }
        } else {
          print("User data is null");
        }
      } else {
        print("Document does not exist");
      }

      // Return false if the document doesn't exist or doesn't contain the 'requested' field
      return false;
    } catch (e) {
      print("Error checking if current user is requested: $e");
      return false;
    }
  }

  Future<bool> isAllowedToChat(String currentUserId, String otherUserId) async {
    try {
      // Get the document of the current user
      DocumentSnapshot currentUserSnapshot = await _firestore.collection('users').doc(currentUserId).get();

      // Check if the document exists and if it contains the 'following' field
      if (currentUserSnapshot.exists) {
        print("Current user document exists");
        Map<String, dynamic>? userData = currentUserSnapshot.data() as Map<String, dynamic>?;

        if (userData != null) {
          print("User data retrieved: $userData");
          if (userData.containsKey('following') || userData.containsKey('following')) {
            List<dynamic> requestedList = userData['requested'] ?? [];
            List<dynamic> followingList = userData['following'] ?? [];
            List<dynamic> followerList = userData['followers'] ?? [];
            print("Following list: $followingList");
            bool containsOtherUser = followerList.contains(otherUserId) || followingList.contains(otherUserId) || requestedList.contains(otherUserId);
            print("Does following list contain other user ID ($otherUserId)? $containsOtherUser");
            return containsOtherUser;
          } else {
            print("Following field does not exist");
          }
        } else {
          print("User data is null");
        }
      } else {
        print("Current user document does not exist");
      }

      // Return false if the document doesn't exist or doesn't contain the 'following' field
      return false;
    } catch (e) {
      print("Error checking if current user is following other user: $e");
      return false;
    }
  }






}
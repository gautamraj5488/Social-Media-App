class UserProfile {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String uid;
  final String FCMtoken;
  final String profilePic; // Add this field

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.uid,
    required this.FCMtoken,
    required this.profilePic, // Initialize this in the constructor
  });

}
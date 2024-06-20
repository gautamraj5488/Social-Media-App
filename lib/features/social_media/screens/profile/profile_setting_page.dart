import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';
import 'package:social_media_app/features/social_media/screens/profile/user_profile_widget.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_fuctions.dart';
import '../../../authentication/screens/login/login.dart';

class SettingsPage extends StatefulWidget {
  final UserProfile userProfile;
  SettingsPage({
    super.key,
    required this.userProfile,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(text: widget.userProfile.firstName);
    _lastNameController = TextEditingController(text: widget.userProfile.lastName);
    _usernameController = TextEditingController(text: widget.userProfile.username);
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneNumberController = TextEditingController(text: widget.userProfile.phoneNumber);
    _passwordController = TextEditingController(text: widget.userProfile.password);
    _confirmPasswordController = TextEditingController(text: widget.userProfile.password);
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneNumberController.clear();
    _usernameController.clear();
    _confirmPasswordController.clear();
  }

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isEditingEnabled = false;


  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadProfilePicture(_selectedImage!);
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is not authenticated.");
      showSnackBar(context, "User not authenticated. Please log in.");
      return;
    }

    try {
      String userId = user.uid;
      String path = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      String? downloadUrl = await _uploadFile(imageFile, path);

      if (downloadUrl == null) {
        print("Upload failed.");
        showSnackBar(context, "Error uploading profile picture.");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({'profilePic': downloadUrl});
      print("Profile picture uploaded successfully: $downloadUrl");
      showSnackBar(context, "Profile picture uploaded successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
      showSnackBar(context, "Error uploading profile picture: $e");
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      TaskSnapshot taskSnapshot = await _storage.ref(path).putFile(file);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }
  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
        appBar: SMAAppBar(
          title: Text("Settings and Activity"),
          showBackArrow: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: dark? SMAColors.darkContainer:SMAColors.lightContainer
                ),
                child: Padding(
                  padding: const EdgeInsets.all(SMASizes.defaultSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Personal Information",
                              style: Theme.of(context).textTheme.headlineSmall),
                          isEditingEnabled
                              ? SizedBox.shrink()
                              : IconButton(
                              onPressed: () {
                                showDialog(context: context, builder: (BuildContext context){
                                  return AlertDialog(
                                    actionsAlignment: MainAxisAlignment.spaceAround,
                                    title: Text("Do you want to edit your profile ?"),
                                    actions: [
                                      OutlinedButton(onPressed: (){
                                        Navigator.pop(context);
                                      }, child: Text("No")),
                                      ElevatedButton(onPressed: (){
                                        setState(() {
                                          isEditingEnabled = true;
                                        });
                                        Navigator.pop(context);
                                      }, child: Text("Yes"))
                                    ],
                                  );
                                });
                              }, icon: Icon(Iconsax.edit,))
                        ],
                      ),
                      const SizedBox(height: SMASizes.spaceBtwSections),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (isEditingEnabled) {
                              _pickImage();
                            }
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : widget.userProfile.profilePic.isNotEmpty
                                ? NetworkImage(widget.userProfile.profilePic)
                                : AssetImage('assets/user.png') as ImageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(height: SMASizes.spaceBtwSections),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  enabled: isEditingEnabled? true:false,
                                  controller: _firstNameController,
                                  expands: false,
                                  decoration: const InputDecoration(
                                      labelText: SMATexts.firstName,
                                      prefixIcon: Icon(Iconsax.user)),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your first name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: SMASizes.spaceBtwInputFields),
                              Expanded(
                                child: TextFormField(
                                  enabled: isEditingEnabled? true:false,
                                  controller: _lastNameController,
                                  expands: false,
                                  decoration: const InputDecoration(
                                      labelText: SMATexts.lastName,
                                      prefixIcon: Icon(Iconsax.user)),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your last name';
                                    }
                                    return null;
                                  },
                                ), // TextFormField
                              ),
                            ]),
                            const SizedBox(height: SMASizes.spaceBtwInputFields),
                            TextFormField(
                              enabled: isEditingEnabled? true:false,
                              controller: _usernameController,
                              expands: false,
                              decoration: const InputDecoration(
                                  labelText: SMATexts.userName,
                                  prefixIcon: Icon(Iconsax.user_edit)),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: SMASizes.spaceBtwInputFields),
                            TextFormField(
                              enabled: false,
                              controller: _emailController,
                              decoration: const InputDecoration(
                                  labelText: SMATexts.email,
                                  prefixIcon: Icon(Iconsax.direct)),
                            ),
                            const SizedBox(height: SMASizes.spaceBtwInputFields),

                            /// Phone Number
                            TextFormField(
                              enabled: isEditingEnabled? true:false,
                              controller: _phoneNumberController,
                              decoration: const InputDecoration(
                                  labelText: SMATexts.phoneNumber,
                                  prefixIcon: Icon(Iconsax.call)),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                } else if (value.length < 10) {
                                  return 'Atleast 10 digits required';
                                } else if (value.length > 10) {
                                  return "Provide phone number without country code";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: SMASizes.spaceBtwInputFields),

                            /// Password
                            isEditingEnabled ? TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: SMATexts.password,
                                prefixIcon: Icon(Iconsax.password_check),
                                //suffixIcon: Icon(Iconsax.eye_slash),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                return null;
                              },
                            ):SizedBox.shrink(),
                            isEditingEnabled? const SizedBox(height: SMASizes.spaceBtwInputFields):SizedBox.shrink(),
                            isEditingEnabled ? TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: SMATexts.confirmPassword,
                                prefixIcon: Icon(Iconsax.password_check),
                                //suffixIcon: Icon(Iconsax.eye_slash),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please confirm your password';
                                } else if (value != _passwordController.text) {
                                  return "Password doesn't matches";
                                }
                                return null;
                              },
                            ):SizedBox.shrink(),
                            isEditingEnabled? const SizedBox(height: SMASizes.spaceBtwInputFields):SizedBox.shrink(),
                            isEditingEnabled ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width*0.3,
                                  child: OutlinedButton(onPressed: (){
                                    setState(() {
                                      isEditingEnabled = false;
                                    });
                                  }, child: Text("Cancel")),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width*0.5,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showDialog(context: context, builder: (BuildContext context){
                                        return AlertDialog(
                                          actionsAlignment: MainAxisAlignment.spaceAround,
                                          title: Text("Do you want to update any changes you made ?"),
                                          actions: [
                                            OutlinedButton(onPressed: (){
                                              Navigator.pop(context);
                                              setState(() {
                                                isEditingEnabled = false;
                                              });
                                            }, child: Text("No")),
                                            ElevatedButton(onPressed: () async{
                                              if (_formKey.currentState?.validate() == true) {
                                                setState(() {
                                                  isEditingEnabled = false;
                                                });
                                                await _fireStoreServices.updateUser(
                                                  firstName: _firstNameController.text.trim().capitalizeFirst!.removeAllWhitespace,
                                                  lastName: _lastNameController.text.trim().capitalizeFirst!.removeAllWhitespace,
                                                  username: _usernameController.text.trim(),
                                                  phoneNumber: _phoneNumberController.text.trim(),
                                                  password: _passwordController.text.trim(),
                                                  uid: _fireStoreServices.getCurrentUser()!.uid,
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('User updated successfully')),
                                                );
                                              }
                                              Navigator.pop(context);
                                            }, child: Text("Yes"))
                                          ],
                                        );
                                      });

                                    },
                                    child: const Text(SMATexts.updateAccount),
                                  ),
                                )
                              ],
                            ):SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                  onPressed: (){
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            //color: Colors.white,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(12),topLeft: Radius.circular(12))
                          ),

                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Text('Are you sure to Logout ?'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      FirebaseAuth.instance.signOut();
                                      Navigator.pop(context);
                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context)=> LoginScreen()), (route)=>false);

                                    },
                                    child: Text('Yes'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text("Sign out",style: TextStyle(fontSize: 14,color: Colors.red,fontWeight: FontWeight.w600),)
              )
            ],
          ),
        ));
  }
}

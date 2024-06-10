import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/services/firestore.dart';


import 'app.dart';
import 'firebase_options.dart';

void main() async {


  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  //String FCMtoken = '';
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  await clearCache();
  await deleteOldData();

  // TODO : Add widget Binding
  // TODO : Local Storage
  // TODO : Splash screen
  // TODO : Firebase
  // TODO : Authentication

  runApp(MyApp());

}



Future<void> clearCache() async {
  var cacheManager = DefaultCacheManager();
  await cacheManager.emptyCache();
}

Future<void> deleteOldData() async {
  final dir = await getApplicationDocumentsDirectory();
  final files = dir.listSync();
  for (var file in files) {
    if (file is File && shouldDeleteFile(file)) {
      file.deleteSync();
    }
  }
}

bool shouldDeleteFile(File file) {
  return file.lastAccessedSync().isBefore(DateTime.now().subtract(Duration(days: 30)));
}


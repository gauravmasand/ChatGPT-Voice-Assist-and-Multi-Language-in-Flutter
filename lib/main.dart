import 'package:chatgpt_multi_language/SelectLanguagePage.dart';
import 'package:chatgpt_multi_language/SetAPiKey.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:velocity_x/velocity_x.dart';

import 'UserSimplePreferences.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UserSimplePreferences.init();

  SharedPreferences _preferences = await SharedPreferences.getInstance();
  if (!_preferences.containsKey("MAX_TOKEN")) {
    _preferences.setInt("MAX_TOKEN", 500);
  }
  if (!_preferences.containsKey("CHATGPT_VERSION")) {
    _preferences.setString("CHATGPT_VERSION", "gptTurbo0301");
  }
  if (!_preferences.containsKey("DALLE_2_RESOLUTION")) {
    _preferences.setString("DALLE_2_RESOLUTION", "size512");
  }

  if (!_preferences.containsKey("URL_DALEE")) {
    _preferences.setStringList("URL_DALEE", []);
  }
  if (!_preferences.containsKey("COMMAND_DALLE")) {
    _preferences.setStringList("COMMAND_DALLE", []);
  }
  if (!_preferences.containsKey("TIME_DALLE")) {
    _preferences.setStringList("TIME_DALLE", []);
  }

  // WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static bool flag = false;

  static Future validate() async {
    if (UserSimplePreferences.getLang()!.isNotEmpty) {
      flag = true;
    }
    Vx.log(flag);
  }

  @override
  Widget build(BuildContext context) {
    validate();
    return MaterialApp(
      title: 'ChatGPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: flag ? ChatScreen() : SelectLanguageScreen(),
    );
  }
}

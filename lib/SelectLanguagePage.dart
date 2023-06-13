import 'package:chatgpt_multi_language/SetAPiKey.dart';
import 'package:chatgpt_multi_language/UserSimplePreferences.dart';
import 'package:chatgpt_multi_language/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:language_picker/language_picker_cupertino.dart';
import 'package:language_picker/languages.dart';
import 'package:velocity_x/velocity_x.dart';


class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({Key? key}) : super(key: key);

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {

  Language _selectedCupertinoLanguage = Languages.english;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text("Select the chatting language",
                  style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.displaySmall, fontSize: 22)
              ).py(10).px(15),
            ),
            Image.asset("assets/img/lang_red.png", height: MediaQuery.of(context).size.height*0.3),
            LanguagePickerCupertino(
              pickerSheetHeight: MediaQuery.of(context).size.height*0.3,
              onValuePicked: (Language language) => setState(() {
                _selectedCupertinoLanguage = language;
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () {
                  UserSimplePreferences.setLang(_selectedCupertinoLanguage.name);
                  UserSimplePreferences.setLangCode(_selectedCupertinoLanguage.isoCode);
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SetApiKey(msg: "",)));
                }, child: Text("Save")),
                TextButton(onPressed: () {
                  UserSimplePreferences.setLang("English");
                  UserSimplePreferences.setLangCode("en");
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SetApiKey(msg: "")));
                }, child: Text("Skip"))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

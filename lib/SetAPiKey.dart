import 'package:chatgpt_multi_language/UserSimplePreferences.dart';
import 'package:chatgpt_multi_language/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:language_picker/language_picker_cupertino.dart';
import 'package:language_picker/languages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velocity_x/velocity_x.dart';

class SetApiKey extends StatefulWidget {
  late String msg;
  SetApiKey({Key? key, required this.msg}) : super(key: key);

  @override
  State<SetApiKey> createState() => _SetApiKeyState();
}

class _SetApiKeyState extends State<SetApiKey> {

  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    try {
      controller.text = UserSimplePreferences.getOpenAiApi()!;
    } catch (e) {

    }
  }

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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height*0.1,),
            // Container(
            //   alignment: Alignment.centerLeft,
            //   child: Text("Enter yo",
            //       style: GoogleFonts.poppins(textStyle: Theme.of(context).textTheme.displaySmall, fontSize: 27)
            //   ).py(10).px(15),
            // ),
            Image.asset("assets/img/enter_api_key.png", width: MediaQuery.of(context).size.height*0.4,),
            // DefaultTextStyle(style: TextStyle(
            //   color: Colors.red,
            // ), child: Text(widget.msg),).p(10).objectBottomLeft(),
            Material(
              child: TextField(
                controller: controller,
                // obscureText: true,
                decoration: InputDecoration(
                  hintText: "sk-xxxx xxxx xxxx xxxx",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color:  widget.msg.isEmpty ? Colors.deepPurple : Colors.red,
                  ),
                  labelText: widget.msg.isEmpty ? 'Enter Your API KEY here' : widget.msg,
                ),
              ),
            ).px(12),

            TextButton(onPressed: () {
              UserSimplePreferences.setOpenAiApi(controller.text);
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
            }, child: Text("Save")),

            TextButton(onPressed: () async {
              String url = "https://platform.openai.com/account/api-keys";
              var urllaunchable = await canLaunch(url); //canLaunch is from url_launcher package
              if (urllaunchable) {
                await launch(url); //launch is from url_launcher package to launch URL
              } else {
                VxToast.show(context, msg: "Fail to load");
              }
            }, child: Text("Generate API KEY").text.underline.make()),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt_multi_language/OldDalleRecords.dart';
import 'package:chatgpt_multi_language/SetAPiKey.dart';
import 'package:chatgpt_multi_language/ShowPopDialog.dart';
import 'package:chatgpt_multi_language/UserSimplePreferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:language_picker/language_picker_cupertino.dart';
import 'package:language_picker/languages.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:velocity_x/velocity_x.dart';

import 'chatmessage.dart';
import 'threedots.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  late OpenAI chatGPT;
  bool _isImageSearch = false;
  bool _isTyping = false;
  bool isMicVisible = true;
  bool muteFlag = true;

  Language _selectedCupertinoLanguage = Languages.english;

  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  bool isTaking = false;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  // TODO: STT
  bool _hasSpeech = false;
  bool _logEvents = false;
  bool _onDevice = false;
  final TextEditingController _pauseForController = TextEditingController(text: '5');
  final TextEditingController _listenForController = TextEditingController(text: '30');
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();
  bool sttFinalResult = false;
  bool listening = false;

  // TODO: Interstitial Ads
  late InterstitialAd? _interstitialAd;
  // our app id -> ca-app-pub-3636896275788579/1358127127
  // test ad id -> ca-app-pub-3940256099942544/1033173712
  final interstitialAdUnitId  = "ca-app-pub-3636896275788579/1358127127";

  /// Loads an interstitial ad.
  void interstitialLoadAd() {
    InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            Vx.log('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  requestPermission() async {
    if (await Permission.microphone.status.isDenied) {
      await Permission.microphone.request();
    } else {
      VxToast.show(context, msg: "Audio Conversation will not word without microphone permission", showTime: 3);
    }
    await Permission.notification.request();
  }

  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _logEvents,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;
      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  static bool flagForApi = false;

  // static Future validate() async {
  //   if (UserSimplePreferences.getOpenAiApi()!.isNotEmpty) {
  //     flagForApi = true;
  //   }
  // }

  bool isProperInternetWorking = false;
  Future CheckUserConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          isProperInternetWorking =true;
          // const snackBar = SnackBar(
          //   content: Text('Turn off the data and repress again'),
          // );
          // ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      }
    } on SocketException catch (_) {
      setState(() {
        isProperInternetWorking = false;
        const snackBar = SnackBar(
          content: Text('Check Your Internet Connection!!!'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  Future isApiKeyValid() async {
    String apiKey = UserSimplePreferences.getOpenAiApi().toString();
    try {
      final response = await Dio().get(
        'https://api.openai.com/v1/engines',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      chatGPT = OpenAI.instance.build(
          token: "${UserSimplePreferences.getOpenAiApi()}",
          baseOption: HttpSetup(receiveTimeout: Duration(minutes: 1)));
      Vx.log("Valid API key");
      flagForApi = true;
      setState(() {});
      // return response.statusCode == 200;
    } on Exception catch (e) {

      Vx.log("InValid API key");
      flagForApi = false;
      // return false;
    }
  }

  @override
  void initState() {
    CheckUserConnection();
    // isApiKeyValid();
    requestPermission();
    ///// TODO: interstitialLoadAd();
    initTts();
    initSpeechState();

    super.initState();
  }

  initTts() {
    flutterTts = FlutterTts();
    _setAwaitOptions();

    flutterTts.setLanguage(UserSimplePreferences.getLang() as String);

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        Vx.log("Playing");
        isTaking = true;
      });
    });

    if (isAndroid) {
      flutterTts.setInitHandler(() {
        setState(() {
          Vx.log("TTS Initialized");
        });
      });
    }

    flutterTts.setCompletionHandler(() {
      setState(() {
        Vx.log("Complete");
        isTaking = false;
        // ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        Vx.log("Cancel");
        // ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        Vx.log("Paused");
        // ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        Vx.log("Continued");
        // ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        Vx.log("error: $msg");
        // ttsState = TtsState.stopped;
      });
    });
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      Vx.log(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      Vx.log(voice);
    }
  }

  Future _speak(String text) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (text != null) {
      if (text!.isNotEmpty) {
        await flutterTts.speak(text!);
      }
    }
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    // if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await flutterTts.pause();
    // if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    // chatGPT?.close();
    // chatGPT?.genImgClose();
    _stop();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();
    isMicVisible = true;

    if (_isImageSearch || message.text.startsWith("generate image of") || message.text.startsWith("create image of")  || message.text.startsWith("generate img of")  || message.text.startsWith("create img of")  || message.text.startsWith("Generate image of") || message.text.startsWith("Create image of")  || message.text.startsWith("Generate img of")  || message.text.startsWith("Create img of") || message.text.startsWith("generate image") || message.text.startsWith("create image")  || message.text.startsWith("generate img")  || message.text.startsWith("create img")  || message.text.startsWith("Generate image") || message.text.startsWith("Create image")  || message.text.startsWith("Generate img")  || message.text.startsWith("Create img") ) {

      final request = GenerateImage(message.text, 1, size: getDalle2Resolution());
      final response = await chatGPT!.generateImage(request);

      Vx.log(response!.data!.last!.url!);
      insertNewData(response.data!.last!.url!, isImage: true);
      // UserSimplePreferences.addDalleImage(message.text, response.data!.last!.url!, "${DateTime.now()}");

    } else {
      // model: [kChatGptTurboModel, kChatGptTurbo0301Model]
      try {
        String chatGptResponse = "";

        /// chatGptTurboModel
        final request = ChatCompleteText(model: getGptModel(), maxToken: UserSimplePreferences.getMaxToken(), messages: [Map.of({"role": "user", "content": "${message.text} (response me in ${UserSimplePreferences.getLang()})"})]);
        final response = await chatGPT!.onChatCompletion(request: request);

        chatGptResponse = response!.choices[0].message!.content;
        Vx.log(chatGptResponse);

        if (muteFlag) {
          if (chatGptResponse.contains("```")) {
            Vx.log("Contain Code");
            int start = chatGptResponse.indexOf("```");
            int end = chatGptResponse.lastIndexOf("```");

            String ttsResponse = chatGptResponse.substring(0, start) + ", code example and " + chatGptResponse.substring(end+3, chatGptResponse.length);
            _speak(ttsResponse);
          } else {
            Vx.log("Normal Text");
            _speak(chatGptResponse);
          }
        }

        insertNewData(chatGptResponse, isImage: false);
      } catch (e) {
        _isTyping = false;
        Vx.log(e.toString());
      }
    }
  }

  ImageSize getDalle2Resolution() {
    switch (UserSimplePreferences.getDalle2Res()) {
      case "size256":
        return ImageSize.size256;
      case "size512":
        return ImageSize.size512;
      case "size1024":
        return ImageSize.size1024;
      default:
        Vx.log("Default image size is invoked");
        return ImageSize.size256;
    }
  }

  ChatModel getGptModel() {
    switch (UserSimplePreferences.getChatGPTVersion()) {
      case "gptTurbo0301":
        return ChatModel.gptTurbo0301;
      case "gptTurbo":
        return ChatModel.gptTurbo;
      case "gpt_4":
        return ChatModel.gpt_4;
      case "gpt_4_32k":
        return ChatModel.gpt_4_32k;
      case "gpt_4_32k_0314":
        return ChatModel.gpt_4_32k_0314;
      case "gpt_4_0314":
        return ChatModel.gpt_4_0314;
      default:
        Vx.log("Default gpt model is invoked");
        return ChatModel.gptTurbo0301;
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "AI",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Container(
          width: listening ? MediaQuery.of(context).size.width : (isMicVisible ? 45 : 0),
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Container(
                width: 45,
                margin: EdgeInsets.only(right:  !listening ? 5 : 0, top: 24, bottom: 24),
                height:  isMicVisible ? 40 : 0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(blurRadius: .26, spreadRadius: level * 1.5, color: Colors.lightBlueAccent.withOpacity(.1)),
                  ],
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: IconButton(
                  // key: micBtnTut,
                  icon: Icon(Icons.mic, size: isMicVisible ? 24 : 0, color: listening ? Colors.blueAccent : Colors.black,),
                  onPressed: () {
                    startListening();
                  },
                ).centered(),
              ),
            ),
          ).centered(),
        ).centered(),
        !listening ? Expanded(
          child: TextField(
            onChanged: (value) {
              if (value.isEmpty) {
                isMicVisible = true;
                setState(() {});
              } else {
                isMicVisible = false;
                setState(() {});
              }
            },
            controller: _controller,
            onSubmitted: (value) {
                _sendMessage();
                ///// TODO: interstitialLoadAd();
                _interstitialAd?.show();
              },
            decoration: const InputDecoration.collapsed(hintText: "Ask me here..."),
            keyboardType: TextInputType.multiline,
            maxLines: 30,
            minLines: 1,
          ),
        ) : SizedBox(),
        !listening ? ButtonBar(
          children: [
            IconButton(
              icon: const Icon(Icons.send).p(10),
              onPressed: () {
                _isImageSearch = false;
                _sendMessage();
                ///// TODO: interstitialLoadAd();
                _interstitialAd?.show();
              },
            ),
            IconButton(
                onPressed: () {
                  _isImageSearch = true;
                  _sendMessage();
                  ///// TODO: interstitialLoadAd();
                  _interstitialAd?.show();
                },
                icon: const Icon(Icons.image_outlined))
          ],
        ) : SizedBox(),
      ],
    ).px(listening ? 0 : 16);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: isApiKeyValid(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   // Show a loading screen while the future is in the waiting state
        //   return Center(
        //     child: CircularProgressIndicator(),
        //   );
        // } else {
          // if (snapshot.hasError) {
          //   return Center(
          //     child: Text("Error: ${snapshot.error}"),
          //   );
          // } else {
          //   return Container(
          //     child: flagForApi ? Scaffold(
          //       appBar: _messages.isNotEmpty ? AppBar(
          //         title: Text("ChatGPT & Dall-E2"), actions: [
          //         isTaking ? IconButton(onPressed: () {
          //           _stop();
          //           setState(() {
          //             isTaking = false;
          //           });
          //         }, icon: Icon(Icons.stop)) : IconButton(onPressed: () {
          //           if (muteFlag == true) {
          //             muteFlag = false;
          //             setState(() {});
          //           } else {
          //             muteFlag = true;
          //             setState(() {});
          //           }
          //         },
          //             icon: muteFlag ? Icon(Icons.volume_up_outlined) : Icon(
          //                 Icons.volume_mute_outlined)),
          //         IconButton(onPressed: () {
          //           _moreOptions();
          //         }, icon: Icon(Icons.more_vert_outlined)),
          //       ],) : PreferredSize(child: SizedBox(height: 0, width: 0,),
          //           preferredSize: Size(0, 0)),
          //       body: SafeArea(
          //         child: Column(
          //           children: [
          //             Flexible(
          //                 child: _messages.isNotEmpty ? ListView.builder(
          //                   physics: BouncingScrollPhysics(),
          //                   reverse: true,
          //                   padding: Vx.m8,
          //                   itemCount: _messages.length,
          //                   itemBuilder: (context, index) {
          //                     return _messages[index];
          //                   },
          //                 ) : ListView(
          //                   physics: BouncingScrollPhysics(),
          //                   children: [
          //                     SizedBox(height: 70,),
          //                     Text("ChatGPT").text.xl4.bodyText1(context)
          //                         .make()
          //                         .centered(),
          //                     SizedBox(height: 30,),
          //                     showDetails(Icon(
          //                       Icons.light_mode_outlined, size: 30,), "Examples", [
          //                       '"Explain quantum computing in simple terms" →',
          //                       '"Create image of dog sitting on hill watching Netflix" →',
          //                       '"How do I make an HTTP request in Javascript?" →'
          //                     ], true),
          //                     SizedBox(height: 25,),
          //                     showDetails(Icon(
          //                       Icons.electric_bolt_outlined, size: 30,),
          //                         "Capabilities", [
          //                           "Remembers what user said earlier in the conversation",
          //                           "Allows user to provide follow-up corrections",
          //                           "Trained to decline inappropriate requests"
          //                         ], false),
          //                     SizedBox(height: 25,),
          //                     showDetails(Icon(Icons.warning_amber, size: 30,),
          //                         "Limitations", [
          //                           "May occasionally generate incorrect information",
          //                           "May occasionally produce harmful instructions or biased content",
          //                           "Limited knowledge of world and events after 2021"
          //                         ], false),
          //                   ],
          //                 )
          //             ),
          //             if (_isTyping) const ThreeDots(),
          //             const Divider(
          //               height: 1.0,
          //             ),
          //             Container(
          //               decoration: BoxDecoration(
          //                 color: context.cardColor,
          //               ),
          //               child: _buildTextComposer(),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ) : SetApiKey(),
          //   );
          // }
        // }

        Widget mainChatScreen  = Scaffold(
          appBar: _messages.isNotEmpty ? AppBar(
            title: Text("ChatGPT & Dall-E2"), actions: [
            isTaking ? IconButton(onPressed: () {
              _stop();
              setState(() {
                isTaking = false;
              });
            }, icon: Icon(Icons.stop)) : IconButton(onPressed: () {
              if (muteFlag == true) {
                muteFlag = false;
                setState(() {});
              } else {
                muteFlag = true;
                setState(() {});
              }
            },
                icon: muteFlag ? Icon(Icons.volume_up_outlined) : Icon(
                    Icons.volume_mute_outlined)),
            IconButton(onPressed: () {
              _moreOptions();
            }, icon: Icon(Icons.more_vert_outlined)),
          ],) : PreferredSize(child: SizedBox(height: 0, width: 0,),
              preferredSize: Size(0, 0)),
          body: SafeArea(
            child: Column(
              children: [
                Flexible(
                    child: _messages.isNotEmpty ? ListView.builder(
                      physics: BouncingScrollPhysics(),
                      reverse: true,
                      padding: Vx.m8,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _messages[index];
                      },
                    ) : ListView(
                      physics: BouncingScrollPhysics(),
                      children: [
                        SizedBox(height: 70,),
                        Text("TechGPT").text.xl4.bodyText1(context)
                            .make()
                            .centered(),
                        SizedBox(height: 30,),
                        showDetails(Icon(
                          Icons.light_mode_outlined, size: 30,), "Examples", [
                          '"Explain quantum computing in simple terms" →',
                          '"Create image of dog sitting on hill watching Netflix" →',
                          '"How do I make an HTTP request in Javascript?" →'
                        ], true),
                        SizedBox(height: 25,),
                        showDetails(Icon(
                          Icons.electric_bolt_outlined, size: 30,),
                            "Capabilities", [
                              "Remembers what user said earlier in the conversation",
                              "Allows user to provide follow-up corrections",
                              "Trained to decline inappropriate requests"
                            ], false),
                        SizedBox(height: 25,),
                        showDetails(Icon(Icons.warning_amber, size: 30,),
                            "Limitations", [
                              "May occasionally generate incorrect information",
                              "May occasionally produce harmful instructions or biased content",
                              "Limited knowledge of world and events after 2021"
                            ], false),
                        Divider(),
                        InkWell(
                          child: detailsWidget("Settings"),
                          onTap: () {
                            _moreOptions();
                          },
                        ),
                      ],
                    )
                ),
                if (_isTyping) const ThreeDots(),
                const Divider(
                  height: 1.0,
                ),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                  ),
                  child: _buildTextComposer(),
                ),
              ],
            ),
          ),
        );

        return isProperInternetWorking ? Container(
          child: flagForApi ? mainChatScreen : SetApiKey(
              msg: "Your API key is invalid"
          ),
        ) : mainChatScreen;
      }
    );
  }

  void _openCupertinoLanguagePicker() => showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        height: (MediaQuery.of(context).size.height*0.5)+30,
        child: Column(
          children: [
            DefaultTextStyle(style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              wordSpacing: 1,
            ), child: Text("Select the chatting language")).py(10),
            LanguagePickerCupertino(
              useMagnifier: true,
              pickerSheetHeight: 300,
              onValuePicked: (Language language) => setState(() {
                _selectedCupertinoLanguage = language;
              }),
            ),
            TextButton(onPressed: () {
              Navigator.pop(context);
              UserSimplePreferences.setLang(_selectedCupertinoLanguage.name);
              UserSimplePreferences.setLangCode(_selectedCupertinoLanguage.isoCode);
              flutterTts.setLanguage(UserSimplePreferences.getLang() as String);
            }, child: Text("Save"))
          ],
        ),
      ).px(10);
    }
    );

  void _moreOptions() => showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        height: (MediaQuery.of(context).size.height*0.5)+30,
        child: Column(
          children: [
            TextButton(onPressed: () {
              Navigator.pop(context);
              _openCupertinoLanguagePicker();
            }, child: Text("Change Language")),Divider(),
            TextButton(onPressed: () {
              Navigator.pop(context);
              _showTokenChanger();
            }, child: Text("Token Limit")),Divider(),
            TextButton(onPressed: () {
              Navigator.pop(context);
              _showChatGPTVersion();
            }, child: Text("ChatGPT Version")),Divider(),
            TextButton(onPressed: () {
              Navigator.pop(context);
              _showDalleResolution();
            }, child: Text("Dalle 2 Resolution")),Divider(),
            // TextButton(onPressed: () {
            //   Navigator.pop(context);
            //   Navigator.push(context, MaterialPageRoute(builder: (context) => OldDalleRecords()));
            // }, child: Text("Dalle History")),Divider(),
            TextButton(onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => SetApiKey(msg: "")));
            }, child: Text("Change Api Key")),Divider(),
          ],
        ),
      ).px(10);
    }
    );

  _showDalleResolution() {
    String? _selectedOption = UserSimplePreferences.getDalle2Res()!;
    showCustomBottomDialog(context,
        Container(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 20,),
              DefaultTextStyle(style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                wordSpacing: 1,
              ), child: Text("Select ChatGPT Version")).py(10),
              SizedBox(height: 20,),
              Material(
                child: DropdownButton<String>(
                  value: _selectedOption,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'size256',
                      child: Text('256x256'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'size512',
                      child: Text('512x512'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'size1024',
                      child: Text('1024x1024'),
                    ),
                  ],
                  onChanged: (value) {
                    UserSimplePreferences.setDalle2Res(value!);
                    Vx.log("The current version gpt is ${value}");
                    Navigator.pop(context);
                    VxToast.show(context, msg: 'Saved');
                    // setState(() {
                    //   _selectedOption = value;
                    // });
                  },
                ).px(12),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ),
      height: (MediaQuery.of(context).size.height*0.5)+30,
    );
  }

  _showChatGPTVersion() {
    String? _selectedOption = UserSimplePreferences.getChatGPTVersion()!;
    showCustomBottomDialog(context,
        Container(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 20,),
              DefaultTextStyle(style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                wordSpacing: 1,
              ), child: Text("Select ChatGPT Version")).py(10),
              SizedBox(height: 20,),
              Material(
                child: DropdownButton<String>(
                  value: _selectedOption,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'gptTurbo0301',
                      child: Text('gptTurbo0301'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'gptTurbo',
                      child: Text('gptTurbo'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'gpt_4',
                      child: Text('gpt_4'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'gpt_4_32k',
                      child: Text('gpt_4_32k'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'gpt_4_32k_0314',
                      child: Text('gpt_4_32k_0314'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'gpt_4_0314',
                      child: Text('gpt_4_0314'),
                    ),
                  ],
                  onChanged: (value) {
                    UserSimplePreferences.setChatGPTVersion(value!);
                    Vx.log("The current version gpt is ${value}");
                    Navigator.pop(context);
                    VxToast.show(context, msg: 'Saved');
                    // setState(() {
                    //   _selectedOption = value;
                    // });
                  },
                ).px(12),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ),
      height: (MediaQuery.of(context).size.height*0.5)+30,
    );
  }

  _showTokenChanger() {
    TextEditingController controller = TextEditingController();
    try {
      controller.text = UserSimplePreferences.getMaxToken()!.toString();
    } catch (e) {
      Vx.log("Exception occur in UserSimplePreferences.getMaxToken | ${e.toString()}");
    }
    showCustomBottomDialog(context,
        Container(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 20,),
              DefaultTextStyle(style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                wordSpacing: 1,
              ), child: Text("Enter Max Token Capacity")).py(10),
              SizedBox(height: 20,),
              Material(
                child: TextField(
                  controller: controller,
                  onChanged: (v) {

                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Max Token Limit',
                  ),
                ),
              ).px(12),
              Spacer(),
              TextButton(onPressed: () {
                if (int.parse(controller.text) <= 4096) {
                  UserSimplePreferences.setMaxToken(int.parse(controller.text));
                  Navigator.pop(context);
                  VxToast.show(context, msg: 'Saved');
                } else {
                  VxToast.show(context, msg: 'The Max Token Capacity is 4096');
                }
              }, child: Text("Save")),
              SizedBox(height: 20,),
            ],
          ),
        ),
      height: (MediaQuery.of(context).size.height*0.5)+30,
    );
  }

  showDetails(Icon icon, String title, List<String> details, bool clickable) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon.px4(),
              Text(title, style: TextStyle(fontSize: 20),).px4(),
            ],
          ),
          SizedBox(height: 10,),
          ListView.builder(
            primary: false,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return InkWell(
                child: detailsWidget(details[index]),
                onTap: () {
                  if (clickable) {
                    _controller.text = details[index].replaceAll('"', "").replaceAll("→", "");
                  }
                },
              );
            },
            itemCount: details.length,
          ),
        ],
      ),
    );
  }

  detailsWidget(String desc) {
    return Container(
      child: Text(desc).text.center.make().p(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
    ).px(25).py(5);
  }

  void startListening() {
    _stop();
    _logEvent('start listening');
    listening = true;
    setState(() {});
    lastWords = '';
    lastError = '';
    final pauseFor = int.tryParse(_pauseForController.text);
    final listenFor = int.tryParse(_listenForController.text);
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: listenFor ?? 30),
      pauseFor: Duration(seconds: pauseFor ?? 3),
      partialResults: true,
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      onDevice: _onDevice,
    );
    setState(() {});
  }

  void stopListening() {
    listening = false;
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    listening = false;
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      sttFinalResult = result.finalResult;
      lastWords = '${result.recognizedWords}';
      _controller.text = lastWords;
      level = 0.0;
      listening = false;

      if (sttFinalResult) {
        _isImageSearch = false;
        _sendMessage();
        ///// TODO: interstitialLoadAd();
        _interstitialAd?.show();
      }
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent('Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      Vx.log('$eventTime $eventDescription');
    }
  }

  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }

  void _switchOnDevice(bool? val) {
    setState(() {
      _onDevice = val ?? false;
    });
  }

}
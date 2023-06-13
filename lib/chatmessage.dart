import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:language_picker/languages.dart';
import 'package:velocity_x/velocity_x.dart';

import 'ShowPopDialog.dart';

class ChatMessage extends StatefulWidget {
  const ChatMessage({super.key,
    required this.text,
    required this.sender,
    this.isImage = false});

  final String text;
  final String sender;
  final bool isImage;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {

  NativeAd? nativeAd;
  bool isNativeAdLoaded = false;
  bool wantSmallNativeAd = true;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    loadNativeAd();
  }

  void loadNativeAd() {
    nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-3636896275788579/8092946507',
      factoryId: wantSmallNativeAd ? "listTile" : "listTileMedium",
      listener: NativeAdListener(onAdLoaded: (ad) {
        setState(() {
          isNativeAdLoaded = true;
        });
      }, onAdFailedToLoad: (ad, error) {
        // loadNativeAd2();
        nativeAd!.dispose();
      }),
      request: const AdRequest(),
    );
    nativeAd!.load();
  }

  _showDetailImage(BuildContext context, String url) {
    showCustomBottomDialog(context,
      Container(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 20,),
            Image.network(url).px(12),
            SizedBox(height: 20,),
          ],
        ),
      ),
      height: (MediaQuery.of(context).size.height*0.5)+30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: widget.sender == "user" ? Vx.gray50.withOpacity(0.5) : Vx.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.sender != "user" ? Text(widget.sender)
                  .text
                  .subtitle1(context)
                  .make()
                  .box
                  .color(widget.sender == "user" ? Vx.red200 : Vx.green200)
                  .p16
                  .rounded
                  .alignCenter
                  .makeCentered() : SizedBox(),
              Expanded(
                child: widget.isImage
                    ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () async {
                        // await showDialog(context: context, builder: (_) => imageDialog("Dall-E2 Generated Image", widget.text, context));
                        _showDetailImage(context, widget.text);
                      },
                      child: Image.network(
                        widget.text,
                        loadingBuilder: (context, child, loadingProgress) =>
                        loadingProgress == null
                            ? child
                            : Center(child: const CircularProgressIndicator.adaptive()),
                      ),
                    ),
                  ),
                )
                // : Container(child: text.trim().text.bodyText1(context).make().px8()),
                    : SelectableText(
                  widget.text.trim(),
                  textAlign: widget.sender=="user" ? TextAlign.end : TextAlign.start,
                  style: TextStyle(
                    wordSpacing: 1,
                    letterSpacing: 1,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ).px8(),
              ),
              widget.sender == "user" ? Text(widget.sender)
                  .text
                  .subtitle1(context)
                  .make()
                  .box
                  .color(widget.sender == "user" ? Vx.red200 : Vx.green200)
                  .p16
                  .rounded
                  .alignCenter
                  .makeCentered() : SizedBox(),
            ],
          ).py(12),
        ),
        isNativeAdLoaded && widget.sender != "user" ? Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          height: wantSmallNativeAd ? 100 : 265,
          child: AdWidget(
            ad: nativeAd!,
          ),
        ) : SizedBox(),
      ],
    );
  }

  Widget imageDialog(text, path, context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$text',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close_rounded),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
          Container(
            child: Image.network(
              '$path',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
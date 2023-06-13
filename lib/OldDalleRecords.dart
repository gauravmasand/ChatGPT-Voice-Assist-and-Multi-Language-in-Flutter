import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chatgpt_multi_language/UserSimplePreferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:velocity_x/velocity_x.dart';

import 'ShowPopDialog.dart';

class OldDalleRecords extends StatefulWidget {
  const OldDalleRecords({Key? key}) : super(key: key);

  @override
  State<OldDalleRecords> createState() => _OldDalleRecordsState();
}

class _OldDalleRecordsState extends State<OldDalleRecords> {

  late DalleImageModel model;
  final ScrollController gridScrollController = ScrollController();

  @override
  void initState() {
    getData();
    Future.delayed(const Duration(milliseconds: 0), () {gridScrollController.jumpTo(gridScrollController.position.maxScrollExtent);});
    super.initState();
  }

  getData() {
    model = UserSimplePreferences.getAllDalleImages();
    Vx.log(model.url.length);
    Vx.log(model.command.length);
    Vx.log(model.time.length);
  }

  _showDetailImage(String url, String time, String command) {
    showCustomBottomDialog(context,
      Container(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 20,),
            DefaultTextStyle(style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              wordSpacing: 1,
            ), child: Text(command)).py(10),
            DefaultTextStyle(style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              wordSpacing: 1,
            ), child: Text(time.split('.')[0])),
            SizedBox(height: 20,),
            Image.network(url).px(12),
            SizedBox(height: 20,),
          ],
        ),
      ),
      height: (MediaQuery.of(context).size.height*0.6)+30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dall-E2 History"), actions: [
      ],),
      body: SafeArea(
        child: Container(
          child: AnimationLimiter(
            child: GridView.builder(
              controller: gridScrollController,
              reverse: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4
              ),
              itemCount: model.url.length,
              itemBuilder: (BuildContext context, int index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: InkWell(
                        onTap: () {
                          _showDetailImage(model.url[index], model.time[index], model.command[index]);
                        },
                        child: Container(
                          height: 100,
                          color: Colors.blueAccent,
                          child: Image.network(
                            "${model.url[index]}",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ),
    );
  }

}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

void showCustomBottomDialog(BuildContext context, Widget widget, {height}) => showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        height: height,
        child: widget,
      ).px(10);
    }
);


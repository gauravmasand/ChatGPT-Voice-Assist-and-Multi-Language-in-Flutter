import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:velocity_x/velocity_x.dart';

class ThreeDots extends StatefulWidget {
  const ThreeDots({super.key});

  @override
  ThreeDotsState createState() => ThreeDotsState();
}

class ThreeDotsState extends State<ThreeDots> with SingleTickerProviderStateMixin {
  // AnimationController? _animationController;
  // int _currentIndex = 0;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _animationController = AnimationController(
  //       vsync: this, duration: const Duration(milliseconds: 800))
  //     ..addStatusListener((status) {
  //       if (status == AnimationStatus.completed) {
  //         _currentIndex++;
  //         if (_currentIndex == 3) {
  //           _currentIndex = 0;
  //         }
  //         _animationController!.reset();
  //         _animationController!.forward();
  //       }
  //     });
  //   _animationController!.forward();
  // }
  //
  // @override
  // void dispose() {
  //   _animationController!.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.black,
        size: 40,
      ),
    ).px16();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return AnimatedBuilder(
  //     animation: _animationController!,
  //     builder: (context, child) {
  //       return Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: List.generate(3, (index) {
  //           return Opacity(
  //             opacity: index == _currentIndex ? 1.0 : 0.2,
  //             child: const Text(
  //               '.',
  //               textScaleFactor: 5,
  //             ),
  //           );
  //         }),
  //       );
  //     },
  //   );
  // }
}

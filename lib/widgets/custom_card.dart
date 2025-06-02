import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    this.height,
    this.width,
    this.color,
    required this.widget,
    this.cardElevation,
  });
  final double? height;
  final double? width;
  final Color? color;
  final Widget widget;
  final double? cardElevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.all(5.w),
      //height: height ?? 50.h,
      width: width ?? double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color:color?? Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1, //spread radius
            blurRadius: 2, // blur radius
            offset: const Offset(0, 1), // changes position of shadow
            //first paramerter of offset is left-right
            //second parameter is top to down
          ),
        ],
      ),
      child: widget,
    );
  }
}

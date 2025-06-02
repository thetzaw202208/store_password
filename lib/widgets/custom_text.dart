import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomText extends StatelessWidget {
  final String? text;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final bool? isEllip;
  final int? maxLines;
  const CustomText(
      {super.key,
        required this.text,
        this.color,
        this.fontSize,
        this.textAlign,
        this.fontWeight,
        this.fontFamily,
        this.isEllip = true,
        this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(text ?? "",
        maxLines: maxLines ?? 1,
        style: TextStyle(
            fontFamily: fontFamily,
            color: color ?? Colors.black,
            fontSize: fontSize ?? 12.sp,
            overflow:
            isEllip == false ? TextOverflow.visible : TextOverflow.ellipsis,
            fontWeight: fontWeight ?? FontWeight.normal),
        textAlign: textAlign ?? TextAlign.start);
  }
}

import 'package:flutter/material.dart';

class TemplateScreenUtils {
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
}

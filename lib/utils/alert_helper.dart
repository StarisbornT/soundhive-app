import 'package:flutter/material.dart';
import '../components/custom_alert.dart';

void showCustomAlert({
  required BuildContext context,
  required bool isSuccess,
  required String title,
  required String message,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CustomAlert(
        title: title,
        message: message,
        iconPath: isSuccess ? 'assets/success.gif' : 'assets/cancel.gif',
        backgroundColor: isSuccess ? Colors.white : Colors.white,
        textColor: Colors.black,
        onClose: () => Navigator.of(context).pop(),
      );
    },
  );
}

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ToastHelper {
  static void show(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.greenAccent,
      fontSize: 12,
    );
  }
}
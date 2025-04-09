import 'package:flutter/material.dart';

class AppTheme {
  static const String fontFamily =
      'Cairo'; // Make sure the font family name is correct.

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    fontFamily: fontFamily,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Cairo', // Corrected here
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        side: const BorderSide(color: Colors.black),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
  );

  // // Dark Theme
  // static final ThemeData darkTheme = ThemeData(
  //   fontFamily: fontFamily,
  //   primarySwatch: Colors.blue,
  //   scaffoldBackgroundColor: Colors.black,
  //   appBarTheme: const AppBarTheme(
  //     backgroundColor: Colors.white,
  //     foregroundColor: Colors.black,
  //     elevation: 0,
  //   ),
  //   textTheme: const TextTheme(
  //     displayLarge: TextStyle(
  //         fontFamily: 'Cairo', // Corrected here
  //         fontSize: 32.0,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.white),
  //     bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
  //   ),
  //   inputDecorationTheme: InputDecorationTheme(
  //     filled: true,
  //     fillColor: Colors.black,
  //     border: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(8.0),
  //       borderSide: const BorderSide(color: Colors.white),
  //     ),
  //     enabledBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(8.0),
  //       borderSide: const BorderSide(color: Colors.white),
  //     ),
  //     focusedBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(8.0),
  //       borderSide: const BorderSide(color: Colors.white, width: 2.0),
  //     ),
  //     errorBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(8.0),
  //       borderSide: const BorderSide(color: Colors.red, width: 2.0),
  //     ),
  //     focusedErrorBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(8.0),
  //       borderSide: const BorderSide(color: Colors.red, width: 2.0),
  //     ),
  //   ),
  //   elevatedButtonTheme: ElevatedButtonThemeData(
  //     style: ElevatedButton.styleFrom(
  //       padding: const EdgeInsets.symmetric(vertical: 16.0),
  //       backgroundColor: Colors.white,
  //       foregroundColor: Colors.black,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8.0),
  //       ),
  //     ),
  //   ),
  //   outlinedButtonTheme: OutlinedButtonThemeData(
  //     style: OutlinedButton.styleFrom(
  //       padding: const EdgeInsets.symmetric(vertical: 16.0),
  //       backgroundColor: Colors.black,
  //       foregroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8.0),
  //       ),
  //       side: const BorderSide(color: Colors.white),
  //     ),
  //   ),
  //   textButtonTheme: TextButtonThemeData(
  //     style: TextButton.styleFrom(
  //       padding: const EdgeInsets.symmetric(vertical: 16.0),
  //       backgroundColor: Colors.white,
  //       foregroundColor: Colors.black,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8.0),
  //       ),
  //     ),
  //   ),
  // );
}

import 'package:flutter/material.dart';

// ThemeData instance with primary color based on light blue
ThemeData lightBlueTheme = ThemeData(
  primaryColor: Colors.lightBlue,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.lightBlue,
  ).copyWith(tertiary: Colors.orange),
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black87),
  ),
  appBarTheme: const AppBarTheme(
    color: Colors.lightBlue,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  useMaterial3: true,
  iconTheme: const IconThemeData(color: Colors.lightBlue, size: 20),
);

// ThemeData instance with primary color based on lemon green
ThemeData lemonGreenTheme = ThemeData(
  primaryColor: Colors.lightGreen,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.lightGreen,
  ).copyWith(tertiary: const Color(0xFFFF6F61)), // Coral color
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black87),
  ),
  appBarTheme: const AppBarTheme(
    color: Colors.lightGreen,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  useMaterial3: true,
  iconTheme: const IconThemeData(color: Colors.lightGreen, size: 20),
);

// ThemeData instance with primary color based on brick red or orange
ThemeData brickRedTheme = ThemeData(
  primaryColor: Colors.deepOrange,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.deepOrange,
  ).copyWith(tertiary: Colors.teal),
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFF2F2F2)),
    bodyMedium: TextStyle(color: Color(0xFFF2F2F2)),
    bodySmall: TextStyle(color: Color(0xFFF2F2F2)),
  ),
  appBarTheme: const AppBarTheme(
    color: Colors.deepOrange,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  useMaterial3: true,
  iconTheme: const IconThemeData(color: Colors.deepOrange, size: 20),
);

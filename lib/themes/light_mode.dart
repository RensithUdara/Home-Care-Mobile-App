import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.light(
      surface: const Color.fromARGB(255, 239, 239, 239),
      primary: const Color.fromARGB(255, 234, 234, 234),
      secondary: Colors.grey,
      tertiary: const Color.fromARGB(185, 218, 218, 218),
      inversePrimary: Colors.grey.shade700,
    ));

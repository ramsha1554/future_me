import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home.dart';
import 'models/future_message.dart';
import 'repository/message_repository.dart';

// Color palette as defined in UIUX_SPEC.md
class AppColors {
  static const Color softCream = Color(0xFFFFF9F2);
  static const Color warmBeige = Color(0xFFF3E6D5);
  static const Color deepBurgundy = Color(0xFF800020);
  static const Color softCoral = Color(0xFFD45060);
  static const Color editorialInk = Color(0xFF231B1B);
  static const Color editorialMuted = Color(0xFF6E615A);
  static const Color hairlineBorder = Color(0xFFE3D2BF);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = MessageRepository();
  await repository.init();
  runApp(FutureMeApp(repository: repository));
}

class FutureMeApp extends StatelessWidget {
  final MessageRepository repository;
  const FutureMeApp({Key? key, required this.repository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future Me',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.softCream,
        primaryColor: AppColors.deepBurgundy,
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 40,
            fontWeight: FontWeight.w400,
          ),
          headlineMedium: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: GoogleFonts.dmSans(
            color: AppColors.editorialMuted,
            fontSize: 19,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.dmSans(
            color: AppColors.editorialMuted,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: AppColors.deepBurgundy,
            onPrimary: AppColors.softCream,
            textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            primary: AppColors.deepBurgundy,
            side: const BorderSide(color: AppColors.deepBurgundy),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.softCream,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.editorialInk),
          titleTextStyle: TextStyle(color: AppColors.editorialInk, fontSize: 20),
        ),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}

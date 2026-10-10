import 'package:flutter/material.dart';
import 'repository/message_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home.dart';
import 'services/notification_service.dart';



// App color palette.
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
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  final repository = MessageRepository();
  await repository.init();
  for (final message in repository.messages) {
    if (!message.isUnlocked) {
      await NotificationService.instance.scheduleUnlock(message);
    }
  }
  runApp(FutureMeApp(repository: repository));
}

class FutureMeApp extends StatelessWidget {
  final MessageRepository repository;
  const FutureMeApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future Me',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.softCream,
        primaryColor: AppColors.deepBurgundy,
        colorScheme: const ColorScheme.light(
          primary: AppColors.deepBurgundy,
          surface: AppColors.softCream,
          onSurface: AppColors.editorialInk,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 40,
            fontWeight: FontWeight.w400,
            height: 48 / 40,
          ),
          headlineLarge: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            height: 40 / 32,
          ),
          headlineMedium: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            height: 36 / 28,
          ),
          headlineSmall: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            height: 32 / 24,
          ),
          bodyLarge: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 19,
            fontWeight: FontWeight.w400,
            height: 30 / 19,
          ),
          bodyMedium: GoogleFonts.dmSans(
            color: AppColors.editorialMuted,
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 26 / 17,
          ),
          bodySmall: GoogleFonts.dmSans(
            color: AppColors.editorialMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
          labelLarge: GoogleFonts.dmSans(
            color: AppColors.softCream,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 20 / 15,
          ),
          labelMedium: GoogleFonts.dmSans(
            color: AppColors.editorialMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 18 / 13,
          ),
          labelSmall: GoogleFonts.dmSans(
            color: AppColors.editorialMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 14 / 11,
            letterSpacing: 1.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBurgundy,
            foregroundColor: AppColors.softCream,
            textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.deepBurgundy,
            side: const BorderSide(color: AppColors.deepBurgundy, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.softCream,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.editorialInk),
          titleTextStyle: GoogleFonts.ebGaramond(
            color: AppColors.editorialInk,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.hairlineBorder,
          thickness: 1,
          space: 1,
        ),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/navigation_root.dart';
import 'package:google_fonts/google_fonts.dart'; // Proje adına göre yolu düzenle

Future<void> main() async {
  // Flutter binding'lerinin ve eklenti kanallarının hazır olduğundan emin olmamızı sağlar.
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe yerelleştirme verilerini uygulama başlamadan önce güvenle yüklüyoruz.
  await initializeDateFormatting('tr_TR', null);

  // Uygulamayı çalıştırıyoruz.
  runApp(MileageLogApp());
}

class MileageLogApp extends StatelessWidget {
  const MileageLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return CupertinoApp(
      title: 'KM Defteri',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemYellow,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,

        // textTheme özelliğini ayarlayarak tüm uygulama fontunu değiştiriyoruz.
        textTheme: CupertinoTextThemeData(
          // GoogleFonts.<font_adi>TextStyle() metodu ile istediğimiz fontu uyguluyoruz.
          // .copyWith() ile mevcut temanın rengini koruyoruz.
          textStyle: GoogleFonts.roboto().copyWith(
            color: baseTextStyle.color,
            fontSize: 16,
          ),
          actionTextStyle: GoogleFonts.roboto().copyWith(
            color: CupertinoColors.activeBlue,
          ),
          navTitleTextStyle: GoogleFonts.roboto().copyWith(
            fontWeight: FontWeight.bold,
            color: baseTextStyle.color,
            fontSize: 24,
          ),
          navLargeTitleTextStyle: GoogleFonts.roboto().copyWith(
            fontWeight: FontWeight.bold,
            color: baseTextStyle.color,
            fontSize: 34,
          ),
          tabLabelTextStyle: GoogleFonts.roboto().copyWith(fontSize: 10),
          pickerTextStyle: GoogleFonts.roboto().copyWith(
            color: baseTextStyle.color,
            fontSize: 21,
          ),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      home: const NavigationRoot(),
    );
  }
}

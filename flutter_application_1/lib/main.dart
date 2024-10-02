import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_export.dart';

var globalMessegerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    prefUtils().init();
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    builder:
    (context, Orientation, KeyEventDeviceType)
    {
      return BlockProvider(
        create:(context)=>ThemeBloc(
          ThemeState(
            themeType:prefUtils().getThemeData(),
          ),
        ),
        child:BlockBuilder<ThemeBloc,ThemeState>(
          builder:(context,State){
            return MaterialApp(
              theme:theme,
              title:'login'
              navigatorKey: NavigatorService.navigatorKey,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                AppLocalizationDelegate(),
                GlobalMateralLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate
              
              ],
              supportedLocales: [
                Locale(
                  'en',
                  '',
                )
              
              ],
              inirialRoute:AppRoutes.initialRoute,
              routes:AppRoutes.routes,
            );
          },
        ),
      );
    },
    );
  }
}
    




import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'stateManagement/preferencesData.dart';
import 'statemanagement/installedMods.dart';
import 'utils/loggingWrapper.dart';
import 'widgets/modManager/mainLayout.dart';
import 'widgets/theme/customTheme.dart';
import 'widgets/misc/mousePosition.dart';
import 'widgets/TitleBar/TitleBar.dart';

void main() {
  loggingWrapper(init);
}

void init() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(700, 400),
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    var windowPos = await windowManager.getPosition();
    if (windowPos.dy < 50)
      await windowManager.setPosition(windowPos.translate(0, 50));
    // await windowManager.focus();
  });

  await PreferencesData().init();
  await installedMods.load();

  runApp(const MyApp());
}

final _rootKey = GlobalKey<ScaffoldState>(debugLabel: "RootGlobalKey");

BuildContext getGlobalContext() => _rootKey.currentContext!;

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nier Music Mod Manager",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: NierTheme.light,
        primaryColor: NierTheme.dark,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: "FiraCode",
          fontSizeFactor: 1.4,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: NierTheme.dark,
          selectionColor: NierTheme.brownDark,
          selectionHandleColor: NierTheme.brownDark,
        ),
      ),
      home: MyAppBody(key: _rootKey)
    );
  }
}

class MyAppBody extends StatelessWidget {
  const MyAppBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NierTheme.light,
      child: CustomPaint(
        foregroundPainter: const NierOverlayPainter(),
        child: MousePosition(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  TitleBar(),
                  Expanded(child: MainLayout()),
                ],
              ),
        ),
      ),
    );
  }
}

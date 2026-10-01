import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'store.dart';

void main() {
  runApp(const ZikrFlowApp());
}

class ZikrFlowApp extends StatefulWidget {
  const ZikrFlowApp({super.key});

  @override
  State<ZikrFlowApp> createState() => _ZikrFlowAppState();
}

class _ZikrFlowAppState extends State<ZikrFlowApp> {
  final ZikrStore _store = ZikrStore();
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _store.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ZikrStore>.value(
      value: _store,
      child: MaterialApp(
        title: 'ZikrFlow',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ur'),
        supportedLocales: const [Locale('ur'), Locale('en')],
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF4ADE80),
          brightness: Brightness.dark,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  backgroundColor: Color(0xFF061713),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
                  ),
                );
              }
              return const HomePage();
            },
          ),
        ),
      ),
    );
  }
}

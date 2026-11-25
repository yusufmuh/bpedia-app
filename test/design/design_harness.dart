import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/shot.dart';

/// Lebar ponsel sempit yang dipakai aturan "200% tanpa luapan" (SPEC §11).
const Size narrowPhone = Size(360, 760);

/// Memasang [child] dalam aplikasi bertema Bpedia pada layar [size] dengan
/// skala huruf [textScale]. Luapan tata letak otomatis menggagalkan tes.
Future<void> pumpDesign(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  Size size = narrowPhone,
  bool reduceMotion = false,
  bool scroll = true,
  Widget? bottom,
  PreferredSizeWidget? appBar,
}) async {
  await loadShotFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? BpTheme.dark() : BpTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: app ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        appBar: appBar,
        bottomNavigationBar: bottom,
        body: scroll ? SingleChildScrollView(child: child) : child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

/// Ukuran area ketuk widget pertama yang cocok dengan [finder].
Size tapAreaOf(WidgetTester tester, Finder finder) =>
    tester.getSize(finder.first);

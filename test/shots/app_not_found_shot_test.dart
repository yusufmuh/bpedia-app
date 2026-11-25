import 'package:bpedia_app/app/app_router.dart';
import 'package:bpedia_app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/shot.dart';

void main() {
  for (final dark in <bool>[false, true]) {
    final suffix = dark ? 'gelap' : 'terang';

    testWidgets('halaman 404 bawaan $suffix', (tester) async {
      await shot(
        tester,
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? BpTheme.dark() : BpTheme.light(),
          home: DefaultNotFoundPage(location: '/tidak-ada', onHome: (_) {}),
        ),
        name: 'app_404_bawaan_$suffix',
      );
      expect(find.text('Waduh, tujuanmu nggak ada!'), findsOneWidget);
      expect(find.text('Ke Beranda'), findsOneWidget);
    });
  }
}

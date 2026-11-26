import 'package:bpedia_app/data/address/address_repository.dart';
import 'package:bpedia_app/features/account_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../orders/f2_harness.dart';

const AddressDraft _office = AddressDraft(
  label: 'Kantor',
  recipient: 'Sinta Maharani',
  phone: '081234567891',
  street: 'Jl. Sudirman Kav. 21',
  district: 'Setiabudi',
  city: 'Jakarta Selatan',
  province: 'DKI Jakarta',
  postalCode: '12920',
);

void main() {
  testWidgets('Ubah alamat di checkout membuka buku alamat asli; alamat yang '
      'diketuk menjadi utama dan dipakai checkout', (tester) async {
    final services = f2Services();
    services.addresses.add(_office);
    registerAccountRoutes(services.router);
    services.cart.add(sunscreen);
    await pumpF2(tester, services, location: '/checkout');

    expect(services.addresses.primary!.label, 'Rumah');
    expect(find.textContaining('Rumah · Sinta Maharani'), findsOneWidget);

    await tester.tap(find.text('Ubah'));
    await settle(tester);
    expect(find.text('Pilih alamat kirim'), findsOneWidget);
    expect(
      find.text('Ketuk alamat untuk dipakai sebagai alamat kirim.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kantor'));
    await settle(tester);
    expect(services.addresses.primary!.label, 'Kantor');
    expect(find.text('Pilih alamat kirim'), findsNothing);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.textContaining('Kantor · Sinta Maharani'), findsOneWidget);
    expect(find.textContaining('Jl. Sudirman Kav. 21'), findsOneWidget);

    await tester.tap(find.text('Buat pesanan'));
    await settle(tester);
    expect(services.orders.orders.single.address.label, 'Kantor');
  });
}

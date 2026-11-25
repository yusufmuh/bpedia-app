import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/shell.dart' show CartButton;
import '../../data/orders/order_repository.dart';
import '../../design/design.dart';
import '../cart/widgets/line_parts.dart';
import '../cart/widgets/recommendations.dart';
import 'widgets/order_card.dart';

/// Tab Transaksi (`/pesanan?status=`): tab status gulir dengan jumlah, kartu
/// pesanan, keadaan kosong per tab, dan ajakan masuk untuk tamu.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  /// Urutan tab: semua, lalu status sesuai alur pesanan.
  static const List<OrderStatus?> tabs = <OrderStatus?>[
    null,
    OrderStatus.awaitingPayment,
    OrderStatus.packing,
    OrderStatus.shipped,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: OrdersPage.tabs.length,
    vsync: this,
  );
  AppServices? _services;
  bool _checking = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    if (identical(services, _services)) return;
    _services?.router.tabRoute.removeListener(_syncTab);
    _services = services;
    services.router.tabRoute.addListener(_syncTab);
    _syncTab();
    unawaited(_cancelOverdue(services));
  }

  @override
  void dispose() {
    _services?.router.tabRoute.removeListener(_syncTab);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cancelOverdue(AppServices services) async {
    await services.orders.cancelOverdue();
    if (mounted) setState(() => _checking = false);
  }

  void _syncTab() {
    final route = _services?.router.tabRoute.value;
    if (route is! OrdersRoute) return;
    final index = OrdersPage.tabs.indexOf(OrderStatus.fromParam(route.status));
    if (index >= 0 && index != _tabs.index) _tabs.index = index;
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = context.bp;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.orders,
        services.auth,
      ]),
      builder: (context, _) {
        final loggedIn = services.auth.isLoggedIn;
        return Scaffold(
          backgroundColor: c.canvas,
          appBar: BpAppBar(
            title: 'Transaksi',
            showBack: false,
            actions: const <Widget>[CartButton()],
            bottom: loggedIn
                ? TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: <Widget>[
                      for (final status in OrdersPage.tabs)
                        Tab(text: _tabLabel(services, status)),
                    ],
                  )
                : null,
          ),
          body: !loggedIn
              ? _GuestOrders(services: services)
              : TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    for (final status in OrdersPage.tabs)
                      _checking
                          ? const _OrdersSkeleton()
                          : _OrderList(services: services, status: status),
                  ],
                ),
        );
      },
    );
  }

  static String _tabLabel(AppServices services, OrderStatus? status) {
    if (status == null) return 'Semua';
    final count = services.orders.countOf(status);
    final active = status.isActive;
    return active && count > 0 ? '${status.label} ($count)' : status.label;
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.services, required this.status});

  final AppServices services;
  final OrderStatus? status;

  @override
  Widget build(BuildContext context) {
    final orders = services.orders.byStatus(status);
    if (orders.isEmpty) {
      final label = status?.label.toLowerCase();
      return ListView(
        children: <Widget>[
          Section(
            child: EmptyState(
              illustration: const FloatingBipy(
                pose: 'pose_belanja',
                height: 140,
              ),
              title: status == null
                  ? 'Belum ada pesanan'
                  : 'Belum ada pesanan $label',
              message: status == null
                  ? 'Pesanan yang kamu buat akan muncul di sini.'
                  : 'Pesanan dengan status ini akan muncul di sini.',
              actionLabel: 'Mulai belanja',
              onAction: () => services.router.go(context, const HomeRoute()),
            ),
          ),
          const RecommendationSection(exclude: <String>[]),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: BpSpace.sectionGap),
      itemCount: orders.length + 1,
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return const RecommendationSection(
            title: 'Belanja lagi, yuk',
            exclude: <String>[],
          );
        }
        final order = orders[index];
        return OrderCard(order: order, busy: services.orders.isBusy(order.id));
      },
    );
  }
}

class _GuestOrders extends StatelessWidget {
  const _GuestOrders({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Section(
          child: EmptyState(
            illustration: const FloatingBipy(pose: 'pose_host', height: 150),
            title: 'Masuk untuk melihat pesananmu',
            message:
                'Lacak pesanan, bayar tagihan, dan tandai pesanan diterima '
                'di sini, Babes.',
            actionLabel: 'Masuk',
            onAction: () => services.router.go(
              context,
              const LoginRoute(next: AppRoutes.orders),
            ),
            secondaryLabel: 'Belanja dulu',
            onSecondary: () => services.router.go(context, const HomeRoute()),
          ),
        ),
        const RecommendationSection(exclude: <String>[]),
      ],
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Semantics(
      label: 'Memuat pesanan',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: BpSpace.sectionGap),
        children: <Widget>[
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BpSpace.sectionGap),
              child: ColoredBox(
                color: c.surface,
                child: const Padding(
                  padding: EdgeInsets.all(BpSpace.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Skeleton.line(width: 160, height: 14),
                      SizedBox(height: BpSpace.x3),
                      Row(
                        children: <Widget>[
                          Skeleton(width: 64, height: 64),
                          SizedBox(width: BpSpace.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Skeleton.line(),
                                SizedBox(height: 6),
                                Skeleton.line(width: 100),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

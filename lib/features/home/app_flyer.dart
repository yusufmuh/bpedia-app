/// App Flyer [K11]: pop-up promo 1:1 dari `promo.json`, maksimal sekali per
/// hari WIB (SPEC §4.1), bisa ditutup dengan tombol bulat atau ketuk luar.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_scope.dart';
import '../../data/promo/promo_repository.dart';
import '../../design/design.dart';
import '../catalog/shop_common.dart';

/// Menampilkan flyer aktif hari ini bila belum tampil hari ini. Mengembalikan
/// apakah flyer ditampilkan.
Future<bool> maybeShowDailyFlyer(BuildContext context) async {
  final promo = AppScope.of(context).promo;
  if (!promo.shouldShowFlyerToday()) return false;
  final flyer = promo.activeFlyer;
  if (flyer == null) return false;
  promo.markFlyerShown();
  await showAppFlyer(context, flyer);
  return true;
}

/// Menampilkan flyer aktif hari ini tanpa memeriksa batas harian (tombol
/// "Tampilkan App Flyer" di Mode Demo). Mengembalikan false bila tidak ada
/// flyer aktif.
Future<bool> showActiveAppFlyer(BuildContext context) async {
  final flyer = AppScope.of(context).promo.activeFlyer;
  if (flyer == null) return false;
  await showAppFlyer(context, flyer);
  return true;
}

/// Menampilkan [flyer] sebagai dialog.
Future<void> showAppFlyer(BuildContext context, PromoFlyer flyer) async {
  final reduce = BpMotion.reduced(context);
  final scrim = context.bp.scrim;
  final open = await showGeneralDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Tutup promo',
    barrierColor: scrim,
    transitionDuration: reduce
        ? const Duration(milliseconds: 200)
        : BpMotion.emphasis,
    pageBuilder: (context, animation, secondaryAnimation) =>
        AppFlyerDialog(flyer: flyer),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      if (reduce) return FadeTransition(opacity: fade, child: child);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
  if (open == true && context.mounted) openAppLocation(context, flyer.route);
}

/// Isi dialog flyer: gambar 1:1 radius 16, tombol tutup bulat di luar sudut
/// kanan atas, pil CTA di tepi bawah gambar, dan petunjuk tutup. Gambar dan
/// CTA sama-sama membuka promo.
class AppFlyerDialog extends StatelessWidget {
  const AppFlyerDialog({required this.flyer, super.key});

  final PromoFlyer flyer;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final screen = MediaQuery.sizeOf(context);
    final side = (screen.width - 64).clamp(200.0, 360.0);
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BpSpace.x5),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: 'Promo: ${flyer.title}',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Material(
                    type: MaterialType.transparency,
                    child: IconButton(
                      key: const ValueKey<String>('flyer-tutup'),
                      tooltip: 'Tutup promo',
                      onPressed: () => Navigator.of(context).pop(false),
                      style: IconButton.styleFrom(
                        backgroundColor: c.surface,
                        foregroundColor: c.text,
                        minimumSize: const Size(40, 40),
                      ),
                      icon: const Icon(LucideIcons.x, size: 20),
                    ),
                  ),
                  const SizedBox(height: BpSpace.x2),
                  SizedBox(
                    width: side,
                    height: side + 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        BpTappable(
                          key: const ValueKey<String>('flyer-lihat'),
                          onTap: () => Navigator.of(context).pop(true),
                          semanticLabel: 'Lihat promo ${flyer.title}',
                          focusRadius: const BorderRadius.all(
                            Radius.circular(16),
                          ),
                          builder: (context, states) => DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              boxShadow: BpShadows.floating(c),
                            ),
                            child: AssetPicture(
                              flyer.image,
                              width: side,
                              height: side,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Center(
                            child: _FlyerCta(
                              label: flyerCtaLabel(flyer),
                              width: (side - 40).clamp(160.0, 255.0),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BpSpace.x3),
                  SizedBox(
                    width: side,
                    child: Text(
                      'Ketuk di luar gambar untuk menutup',
                      textAlign: TextAlign.center,
                      style: BpText.caption.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label tombol flyer: flyer Kelopak mengajak main, selainnya melihat promo.
String flyerCtaLabel(PromoFlyer flyer) =>
    flyer.route.startsWith('/hadiah') ? 'Main sekarang' : 'Lihat promo';

/// Pil CTA isi brand berbingkai putih yang menumpang di tepi bawah gambar.
class _FlyerCta extends StatelessWidget {
  const _FlyerCta({
    required this.label,
    required this.width,
    required this.onPressed,
  });

  final String label;
  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BpRadius.pillAll,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: BpShadows.floating(c),
        ),
        child: PillButton(
          key: const ValueKey<String>('flyer-cta'),
          label: label,
          size: PillButtonSize.small,
          expand: true,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

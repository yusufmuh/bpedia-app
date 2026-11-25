/// Pratinjau App Flyer untuk Mode Demo: gambar 1:1 radius 16, tombol tutup
/// bulat, dan "Lihat promo" (SPEC §4.1, K11). Tidak menandai flyer sudah
/// tampil, supaya jatah sekali sehari di Beranda tetap utuh.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../data/promo/promo_repository.dart';
import '../../design/design.dart';

/// Menampilkan [flyer] sebagai dialog.
Future<void> showDemoFlyer(BuildContext context, PromoFlyer flyer) async {
  final services = AppScope.of(context);
  final open = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup promo',
    barrierColor: context.bp.scrim,
    transitionDuration: BpMotion.reduced(context)
        ? const Duration(milliseconds: 200)
        : BpMotion.emphasis,
    pageBuilder: (dialogContext, _, _) => _FlyerDialog(flyer: flyer),
    transitionBuilder: (dialogContext, animation, _, child) {
      if (BpMotion.reduced(dialogContext)) {
        return FadeTransition(opacity: animation, child: child);
      }
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: child,
        ),
      );
    },
  );
  if (open != true || !context.mounted) return;
  final route = parseAppRoute(flyer.route);
  if (route is NotFoundRoute) return;
  await services.router.go(context, route);
}

class _FlyerDialog extends StatelessWidget {
  const _FlyerDialog({required this.flyer});

  final PromoFlyer flyer;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BpSpace.x8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 1,
                        child: AssetPicture(
                          flyer.image,
                          borderRadius: BorderRadius.circular(16),
                          cacheWidth: 1080,
                          semanticLabel: flyer.title,
                        ),
                      ),
                      Positioned(
                        top: -14,
                        right: -14,
                        child: Tooltip(
                          message: 'Tutup',
                          child: Material(
                            color: c.surface,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.of(context).pop(false),
                              child: SizedBox.square(
                                dimension: BpSize.touch,
                                child: Icon(
                                  LucideIcons.x,
                                  color: c.text,
                                  semanticLabel: 'Tutup promo',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BpSpace.x4),
                  PillButton(
                    label: 'Lihat promo',
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(true),
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

/// Rute grup akun (F3): autentikasi, tab Akun, profil, alamat, pengaturan,
/// notifikasi, info, dan Mode Demo.
///
/// Sambungkan di `main.dart`: `runBpediaApp(routes: [..., registerAccountRoutes])`.
library;

import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../app/app_scope.dart';
import '../design/gallery_page.dart';
import 'account/account_page.dart';
import 'account/profile_page.dart';
import 'address/address_book_page.dart';
import 'address/address_form_page.dart';
import 'auth/change_password_page.dart';
import 'auth/forgot_password_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'demo/demo_page.dart';
import 'info/about_page.dart';
import 'info/help_page.dart';
import 'info/legal_pages.dart';
import 'notifications/inbox_page.dart';
import 'settings/settings_page.dart';

export 'demo/demo_rewards_tools.dart';

/// Mendaftarkan semua halaman dan tab grup akun ke [router].
void registerAccountRoutes(AppRouter router) {
  router
    ..registerTab(AppTab.account, (context) => const AccountPage())
    ..register<LoginRoute>((context, route) => LoginPage(next: route.next))
    ..register<RegisterRoute>(
      (context, route) => RegisterPage(full: route.full, next: route.next),
    )
    ..register<ForgotPasswordRoute>(
      (context, route) => const ForgotPasswordPage(),
    )
    ..register<ChangePasswordRoute>(
      (context, route) => const ChangePasswordPage(),
    )
    ..register<ProfileRoute>((context, route) => const ProfilePage())
    ..register<AddressesRoute>(
      (context, route) => AddressBookPage(selecting: route.selecting),
    )
    ..register<AddressFormRoute>(
      (context, route) => AddressFormPage(addressId: route.addressId),
    )
    ..register<SettingsRoute>((context, route) => const SettingsPage())
    ..register<InboxRoute>((context, route) => const InboxPage())
    ..register<HelpRoute>((context, route) => const HelpPage())
    ..register<AboutRoute>((context, route) => const AboutPage())
    ..register<TermsRoute>((context, route) => const TermsPage())
    ..register<PrivacyRoute>((context, route) => const PrivacyPage())
    ..register<DemoRoute>((context, route) => const DemoPage())
    ..register<GalleryRoute>((context, route) => const _GalleryHost());
}

/// Galeri desain dengan sakelar tema yang tersimpan di pengaturan.
class _GalleryHost extends StatelessWidget {
  const _GalleryHost();

  @override
  Widget build(BuildContext context) => DesignGalleryPage(
    onToggleTheme: () =>
        AppScope.of(context).settings.toggleTheme(Theme.of(context).brightness),
  );
}

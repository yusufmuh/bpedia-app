/// Sinyal browser yang diikuti app di web: preferensi kurangi gerak dan
/// simpanan tab lain ke localStorage. Di luar web semua fungsi tidak berbuat
/// apa-apa, jadi pemanggil tidak perlu memeriksa platform.
library;

export 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart';

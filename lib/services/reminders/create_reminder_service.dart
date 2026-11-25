/// Membuat layanan pengingat untuk platform ini.
///
/// Web tidak pernah memuat flutter_local_notifications: impor bersyarat
/// memilih stub.
library;

export 'create_reminder_service_stub.dart'
    if (dart.library.io) 'create_reminder_service_io.dart';

/// Membuat tujuan analitik AppsFlyer bila platform dan kunci tersedia.
///
/// Web tidak pernah memuat kode AppsFlyer: impor bersyarat memilih stub.
library;

export 'create_analytics_stub.dart'
    if (dart.library.io) 'create_analytics_io.dart';

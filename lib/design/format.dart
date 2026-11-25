/// Format rupiah untuk widget desain: `Rp10.000`, `-Rp12.800`.
String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-Rp' : 'Rp');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Rating satu desimal dengan koma: `4,9`; bilangan bulat tetap `5,0`.
String formatRating(double rating) =>
    rating.toStringAsFixed(1).replaceAll('.', ',');

/// Isi lencana hitungan: `7`, `99+`.
String formatBadgeCount(int count) => count > 99 ? '99+' : '$count';

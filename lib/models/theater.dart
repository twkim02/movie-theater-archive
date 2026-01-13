class Theater {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceKm;
  final List<Showtime> showtimes;
  final String bookingUrl;

  Theater({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.showtimes,
    required this.bookingUrl,
  });
}

class Showtime {
  final String start;
  final String end;
  final String screen;

  const Showtime({
    required this.start,
    required this.end,
    required this.screen,
  });
}

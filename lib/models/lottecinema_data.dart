/// 롯데시네마 영화 정보 모델
class LotteCinemaMovie {
  /// 영화 번호 (롯데시네마 내부 ID)
  final String movieNo;
  
  /// 영화명
  final String movieName;

  LotteCinemaMovie({
    required this.movieNo,
    required this.movieName,
  });

  @override
  String toString() => 'LotteCinemaMovie(movieNo: $movieNo, movieName: $movieName)';
}

/// 롯데시네마 영화관 정보 모델
class LotteCinemaTheater {
  /// 지역 코드
  final String divisionCode;
  
  /// 상세 지역 코드
  final String detailDivisionCode;
  
  /// 영화관 ID
  final String cinemaID;
  
  /// 영화관 이름
  final String element;

  LotteCinemaTheater({
    required this.divisionCode,
    required this.detailDivisionCode,
    required this.cinemaID,
    required this.element,
  });

  /// cinemaID를 "divisionCode|detailDivisionCode|cinemaID" 형식으로 반환
  String get cinemaIdString => '$divisionCode|$detailDivisionCode|$cinemaID';

  @override
  String toString() => 'LotteCinemaTheater(element: $element, cinemaID: $cinemaID)';
}

/// 롯데시네마 상영 시간표 정보 모델
class LotteCinemaSchedule {
  /// 영화명 (한국어)
  final String movieNameKR;
  
  /// 상영 시작 시간 (HH:mm 형식)
  final String startTime;
  
  /// 상영 종료 시간 (HH:mm 형식)
  final String endTime;
  
  /// 상영관 이름 (예: "4관", "7관")
  final String screenNameKR;
  
  /// 전체 좌석 수
  final int totalSeatCount;
  
  /// 예매된 좌석 수
  final int bookingSeatCount;

  LotteCinemaSchedule({
    required this.movieNameKR,
    required this.startTime,
    required this.endTime,
    required this.screenNameKR,
    required this.totalSeatCount,
    required this.bookingSeatCount,
  });

  /// 잔여 좌석 수
  int get availableSeatCount => totalSeatCount - bookingSeatCount;

  /// JSON에서 LotteCinemaSchedule 객체 생성
  factory LotteCinemaSchedule.fromJson(Map<String, dynamic> json) {
    return LotteCinemaSchedule(
      movieNameKR: (json['MovieNameKR'] ?? '').toString(),
      startTime: (json['StartTime'] ?? '').toString(),
      endTime: (json['EndTime'] ?? '').toString(),
      screenNameKR: (json['ScreenNameKR'] ?? '').toString(),
      totalSeatCount: (json['TotalSeatCount'] as num?)?.toInt() ?? 0,
      bookingSeatCount: (json['BookingSeatCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'LotteCinemaSchedule($startTime-$endTime, $screenNameKR, 잔여: $availableSeatCount/$totalSeatCount)';
}

/// 메가박스 영화 정보 모델
class MegaboxMovie {
  /// 영화 번호 (메가박스 내부 ID)
  final String movieNo;
  
  /// 영화명
  final String movieNm;

  MegaboxMovie({
    required this.movieNo,
    required this.movieNm,
  });

  @override
  String toString() => 'MegaboxMovie(movieNo: $movieNo, movieNm: $movieNm)';
}

/// 메가박스 영화관 정보 모델
class MegaboxTheater {
  /// 영화관 번호
  final String brchNo;
  
  /// 영화관 이름
  final String brchNm;

  MegaboxTheater({
    required this.brchNo,
    required this.brchNm,
  });

  @override
  String toString() => 'MegaboxTheater(brchNo: $brchNo, brchNm: $brchNm)';
}

/// 메가박스 상영 시간표 정보 모델
class MegaboxSchedule {
  /// 영화명
  final String movieNm;
  
  /// 상영 시작 시간 (HH:mm 형식)
  final String playStartTime;
  
  /// 상영 종료 시간 (HH:mm 형식)
  final String playEndTime;
  
  /// 상영관 이름 (예: "1관", "2관")
  final String theabExpoNm;
  
  /// 전체 좌석 수
  final int totSeatCnt;
  
  /// 잔여 좌석 수
  final int restSeatCnt;

  MegaboxSchedule({
    required this.movieNm,
    required this.playStartTime,
    required this.playEndTime,
    required this.theabExpoNm,
    required this.totSeatCnt,
    required this.restSeatCnt,
  });

  /// 예매된 좌석 수
  int get bookingSeatCount => totSeatCnt - restSeatCnt;

  /// JSON에서 MegaboxSchedule 객체 생성
  factory MegaboxSchedule.fromJson(Map<String, dynamic> json) {
    return MegaboxSchedule(
      movieNm: (json['movieNm'] ?? '').toString(),
      playStartTime: (json['playStartTime'] ?? '').toString(),
      playEndTime: (json['playEndTime'] ?? '').toString(),
      theabExpoNm: (json['theabExpoNm'] ?? '').toString(),
      totSeatCnt: (json['totSeatCnt'] as num?)?.toInt() ?? 0,
      restSeatCnt: (json['restSeatCnt'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'MegaboxSchedule($playStartTime-$playEndTime, $theabExpoNm, 잔여: $restSeatCnt/$totSeatCnt)';
}

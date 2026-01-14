import requests
import csv
import json


def get_id_from_csv(file_path, name_col, id_col, target_name):
    """CSV 파일에서 이름에 해당하는 ID(번호)를 찾습니다."""
    try:
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row[name_col] == target_name:
                    return row[id_col]
    except FileNotFoundError:
        print(f"오류: {file_path} 파일이 없습니다. 먼저 CSV 생성 코드를 실행해주세요.")
    return None


def fetch_megabox_schedule(theater_nm, movie_nm, play_de="20260114"):
    # 1. CSV에서 영화관 번호와 영화 번호 조회
    brch_no = get_id_from_csv('megabox_theater.csv', 'brchNm', 'brchNo', theater_nm)
    movie_no = get_id_from_csv('megabox_movie.csv', 'movieNm', 'movieNo', movie_nm)

    if not brch_no or not movie_no:
        print(f"정보를 찾을 수 없습니다. (영화관: {brch_no}, 영화: {movie_no})")
        return

    # 2. API 요청 설정
    url = "https://www.megabox.co.kr/on/oh/ohb/SimpleBooking/selectBokdList.do"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Content-Type": "application/json",
        "Referer": "https://www.megabox.co.kr/booking",
        "X-Requested-With": "XMLHttpRequest"
    }

    # 요청 Payload 구성 (조회한 ID 삽입)
    payload = {
        "arrMovieNo": movie_no,
        "playDe": play_de,
        "brchNoListCnt": 1,
        "brchNo1": brch_no,
        "movieNo1": movie_no,
    }

    try:
        # 3. URL 호출 (POST)
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        # 4. 결과 출력 (movieFormList 순회)
        schedules = data.get('movieFormList', [])

        if not schedules:
            print(f"\n'{theater_nm}'에서 '{movie_nm}'의 상영 일정이 없습니다.")
            return

        print(f"\n[ {theater_nm} - {movie_nm} 실시간 상영 정보 ]")
        print("=" * 65)
        print(f"{'상영시간':<10} | {'종료시간':<10} | {'영화제목':<15} | {'상영관':<15} | {'잔여좌석'}")
        print("-" * 65)

        for s in schedules:
            print(
                f"{s.get('playStartTime'):<12} | {s.get('playEndTime'):<12} | {s.get('movieNm'):<17} | {s.get('theabExpoNm'):<18} | {s.get('restSeatCnt')}/{s.get('totSeatCnt')}")
        print("=" * 65)

    except Exception as e:
        print(f"API 호출 중 오류 발생: {e}")


# --- 실행 ---
if __name__ == "__main__":
    # 보고 싶은 영화관과 영화 이름을 입력하세요
    target_theater = "대전중앙로"
    target_movie = "만약에 우리"

    fetch_megabox_schedule(target_theater, target_movie)
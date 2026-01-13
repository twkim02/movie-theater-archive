import requests
import json


def get_movie_schedule():
    url = "https://www.lottecinema.co.kr/LCWS/Ticketing/TicketingData.aspx"

    # 1. 사용자가 캡처한 정보를 그대로 헤더에 반영
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
        "Referer": "https://www.lottecinema.co.kr/NLCHS/Ticketing",
        "Origin": "https://www.lottecinema.co.kr",
        "Content-Type": "application/x-www-form-urlencoded"
    }

    # 2. 캡처한 Payload 구성
    dic_param = {
        "MethodName": "GetPlaySequence",
        "channelType": "HO",
        "osType": "W",
        "osVersion": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
        "playDate": "2026-01-13", # 오늘 날짜 및 내일 날짜 결과를 화면에 띄우고자 함
        "cinemaID": "1|0003|4008", # lottecinema_theater.csv 파일에 있는 divisionCode|detailDivisionCode|cinemaID
        "representationMovieCode": "23663" # lottecinema_movie_now.csv 또는 lottecinema_movie_upcoming.csv 파일에 있는 영화별 movieNo
    }

    payload = {
        "paramList": json.dumps(dic_param)
    }

    try:
        response = requests.post(url, data=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        print(data)

        print(f"--- 롯데시네마 대전센트럴 상영 시간표 ---")

        # 'PlaySeqs' 내의 'Items' 리스트를 순회
        items = data.get("PlaySeqs", {}).get("Items", [])

        if not items:
            print("상영 정보가 없습니다.")
            return

        for item in items:
            movie_nm = item.get("MovieNameKR")
            start_time = item.get("StartTime")
            end_time = item.get("EndTime")
            screen_nm = item.get("ScreenNameKR")  # '4관', '7관' 등
            total_seats = item.get("TotalSeatCount")
            rest_seats = item.get("BookingSeatCount")  # 예매된 좌석 수

            print(f"[{start_time} ~ {end_time}] {movie_nm}")
            print(f"   상영관: {screen_nm} | 잔여: {rest_seats}/{total_seats}석")
            print("-" * 40)

    except Exception as e:
        print(f"오류가 발생했습니다: {e}")


if __name__ == "__main__":
    get_movie_schedule()
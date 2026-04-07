import pandas as pd
import requests

def get_samsung_repair_price():
    url = "https://www.samsung.com/us/support/cracked-screen-repair"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    try:
        # 1. HTML 가져오기 (requests 이용)
        response = requests.get(url, headers=headers)
        response.raise_for_status()

        # 2. Pandas로 모든 표 읽기
        # [match='Galaxy S26'] 옵션을 주면 해당 텍스트가 포함된 표만 골라옵니다.
        tables = pd.read_html(response.text)
        
        target_price = None

        for df in tables:
            # 컬럼명 정리 (공백 제거 등)
            df.columns = [col.strip() for col in df.columns]

            # 'Galaxy S26 Ultra'가 포함된 행 찾기
            # 첫 번째 열(보통 모델명)에서 검색
            mask = df.iloc[:, 0].str.contains('Galaxy S26 Ultra', case=False, na=False)
            
            if mask.any():
                # 'Screen Repair' 컬럼 데이터만 추출
                # 만약 컬럼명이 정확히 일치하지 않을 수 있으므로 'Screen'이 포함된 열 찾기
                screen_col = [c for c in df.columns if 'Screen' in c and 'Module' not in c]
                
                if screen_col:
                    price_val = df.loc[mask, screen_col[0]].values[0]
                    target_price = str(price_val).strip()
                    break

        if target_price:
            print(f"✅ 검색 결과: Galaxy S26 Ultra 단품 수리비 = {target_price}")
            # 가격이 '-' 인 경우에 대한 처리
            if target_price == '-':
                print("⚠️ 현재 단품 수리비가 공지되지 않았습니다 (기호: -)")
            return target_price
        else:
            print("❌ 해당 모델을 찾을 수 없습니다.")

    except Exception as e:
        print(f"🚨 오류 발생: {e}")

if __name__ == "__main__":
    price = get_samsung_repair_price()

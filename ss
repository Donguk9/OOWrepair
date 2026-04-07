import os
import json
import time
import pandas as pd
import requests
from datetime import datetime
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright

# 1. 환경 변수 로드
load_dotenv()
ENDPOINT_URL = os.getenv("endpoint_url")
API_KEY = os.getenv("api_key")

def ask_internal_ai(raw_text, target_model):
    """사내 AI에게 텍스트 분석을 요청합니다."""
    prompt = f"""
    아래는 삼성 서비스 센터의 수리비 페이지에서 추출한 텍스트입니다.
    대상 모델: {target_model}
    
    [지시사항]
    1. 해당 모델의 '액정 단품 수리비(Screen Repair/Display Only)'를 찾으세요.
    2. 만약 Fold 모델이라면 '내부 액정(Inner)'과 '외부 액정(Outer)' 가격을 각각 찾으세요.
    3. 정상가(Original)와 할인가(Discount)가 모두 있다면 구분하세요.
    4. 결과는 반드시 아래 JSON 형식으로만 답변하세요.
    {{
        "model": "{target_model}",
        "screen_type": "Single/Inner/Outer",
        "original_price": "숫자만",
        "discount_price": "숫자만/없으면 null",
        "currency": "ISO코드(USD, THB 등)"
    }}
    
    [텍스트]
    {raw_text[:5000]} # 너무 길면 API 제한에 걸릴 수 있으므로 슬라이싱
    """

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "messages": [{"role": "user", "content": prompt}],
        # 사내 AI 모델명에 맞춰 수정 필요 (예: "gpt-4", "gemini-pro" 등)
        "model": "internal-ai-model" 
    }

    try:
        response = requests.post(ENDPOINT_URL, headers=headers, json=payload)
        response.raise_for_status()
        # AI 답변에서 JSON 부분만 파싱 (사내 API 응답 구조에 맞춰 조정)
        ai_res = response.json()['choices'][0]['message']['content']
        return json.loads(ai_res)
    except Exception as e:
        print(f"AI 분석 실패: {e}")
        return None

def run_automation(target_model_name):
    # 테스트용 사이트 설정 (실제로는 별도 JSON 파일에서 불러오는 것을 권장)
    sites = [
        {"country": "US", "url": "https://www.samsung.com/us/support/cracked-screen-repair", "type": "direct"},
        {"country": "TH", "url": "https://www.samsung.com/th/support/repair-cost", "type": "dropdown", 
         "steps": ["#product-type-select", "text=Smartphone", "#model-search", target_model_name]},
        {"country": "BR", "url": "https://www.samsung.com/br/support/valorreparo", "type": "interaction",
         "steps": ["text=Smartphone", "text=S Series"]}
    ]

    final_data = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False) # 로컬 실행 시 눈으로 확인 가능
        page = browser.new_page()

        for site in sites:
            try:
                print(f"\n🚀 [{site['country']}] 작업 시작...")
                page.goto(site['url'], wait_until="domcontentloaded")
                time.sleep(3)

                # 드롭다운/인터랙션 처리
                if "steps" in site:
                    for step in site['steps']:
                        if step.startswith("#") or step.startswith("."):
                            page.click(step)
                        else:
                            page.get_by_text(step, exact=False).first.click()
                        time.sleep(1.5)

                # 화면의 텍스트 긁기 (가장 확실한 방법)
                raw_text = page.inner_text("body")
                
                # AI에게 정제 요청
                refined_json = ask_internal_ai(raw_text, target_model_name)

                if refined_json:
                    refined_json['country'] = site['country']
                    refined_json['date'] = datetime.now().strftime("%Y-%m-%d")
                    final_data.append(refined_json)
                    print(f"✅ 추출 성공: {refined_json['original_price']}")

            except Exception as e:
                print(f"❌ {site['country']} 에러: {e}")

        browser.close()

    # 엑셀 저장
    if final_data:
        df = pd.DataFrame(final_data)
        filename = f"Repair_Prices_{target_model_name}_{datetime.now().strftime('%H%M')}.xlsx"
        df.to_excel(filename, index=False)
        print(f"\n📊 엑셀 파일 저장 완료: {filename}")

if __name__ == "__main__":
    # 원하는 모델명을 넣고 실행
    run_automation("Galaxy S26 Ultra")

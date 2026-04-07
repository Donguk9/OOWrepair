import pandas as pd
from playwright.sync_api import sync_playwright
from datetime import datetime
import time

# [핵심] 사이트별 행동 지침서 (50개까지 확장 가능)
site_configs = [
    {
        "country": "US",
        "url": "https://www.samsung.com/us/support/cracked-screen-repair",
        "type": "table",
        "target_model": "Galaxy S26 Ultra",
        "wait_selector": "table" # 표가 나타날 때까지 대기
    },
    {
        "country": "TH (Thailand)",
        "url": "https://www.samsung.com/th/support/repair-cost",
        "type": "interaction",
        "target_model": "Galaxy S26 Ultra",
        "steps": [
            {"action": "click", "selector": "#product-type-select", "value": "Smartphone"},
            {"action": "type", "selector": "#model-search", "value": "Galaxy S26 Ultra"}
        ]
    },
    {
        "country": "BR (Brazil)",
        "url": "https://www.samsung.com/br/support/valorreparo",
        "type": "interaction",
        "target_model": "Galaxy S26 Ultra",
        "steps": [
            {"action": "click", "selector": "text=Smartphone"},
            {"action": "click", "selector": "text=S Series"}
        ]
    }
]

# 사내 AI 서비스 연동 함수 (가상의 함수)
def ask_internal_ai(raw_text, model_name):
    """
    사내 AI API를 호출하여 지저분한 텍스트에서 가격 정보만 추출합니다.
    """
    print(f"--- [AI] {model_name} 가격 정보 분석 중... ---")
    # TODO: 여기에 사내 AI API 호출 로직을 넣으세요 (requests.post 등)
    # 예시 프롬프트: "다음 텍스트에서 {model_name}의 Screen Repair 가격만 추출해줘"
    return f"AI 추출 결과: {raw_text[:50]}..." # 임시 반환값

def run_automation():
    results = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False) # 로컬 확인을 위해 창을 띄움
        context = browser.new_context()
        page = context.new_page()

        for config in site_configs:
            try:
                print(f"[{config['country']}] 접속 중...")
                page.goto(config['url'], wait_until="networkidle")
                time.sleep(3) # 안정적인 로딩을 위해 잠시 대기

                # 1. 사이트별 인터랙션 수행 (드롭다운 등)
                if config['type'] == "interaction":
                    for step in config.get('steps', []):
                        if step['action'] == "click":
                            page.click(step['selector'])
                        elif step['action'] == "type":
                            page.fill(step['selector'], step['value'])
                        time.sleep(1)

                # 2. 결과 텍스트 긁기 (가장 넓은 범위의 컨테이너 지정)
                # 사이트마다 가격이 표시되는 영역의 ID나 Class를 적절히 지정
                raw_content = page.content() # 전체 HTML을 긁거나 특정 영역 지정
                
                # 3. 사내 AI를 통해 정밀 분석
                final_price = ask_internal_ai(raw_content, config['target_model'])

                results.append({
                    "Date": datetime.now().strftime("%Y-%m-%d"),
                    "Country": config['country'],
                    "Model": config['target_model'],
                    "Price": final_price,
                    "Status": "Success"
                })

            except Exception as e:
                print(f"[{config['country']}] 실패: {e}")
                results.append({"Country": config['country'], "Status": "Error", "Error": str(e)})

        browser.close()

    # 4. 엑셀 저장
    df = pd.DataFrame(results)
    file_name = f"repair_prices_{datetime.now().strftime('%y%m%d')}.xlsx"
    df.to_excel(file_name, index=False)
    print(f"✅ 저장 완료: {file_name}")

if __name__ == "__main__":
    run_automation()

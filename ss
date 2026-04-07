import asyncio
import pandas as pd
from playwright.async_api import async_playwright
from bs4 import BeautifulSoup

# 1. 크롤링할 국가별 URL 리스트 (여기에 가지고 계신 링크들을 추가하세요)
urls = [
    "https://www.samsung.com/us/support/cracked-screen-repair/",
    # "https://www.samsung.com/uk/support/repair/screen-repair-pricing/", # 예시
    # 추가 링크들...
]

async def scrape_samsung_table(browser, url):
    page = await browser.new_page()
    data_list = []
    
    try:
        print(f"접속 중: {url}")
        # 페이지 이동 (네트워크가 안정될 때까지 대기)
        await page.goto(url, wait_until="networkidle", timeout=60000)
        
        # 미국 사이트 기준 테이블/리스트가 포함된 주요 셀렉터가 나타날 때까지 대기
        # 사이트마다 클래스명이 다를 수 있으므로, 공통적인 키워드를 포함한 요소를 기다립니다.
        try:
            await page.wait_for_selector("[class*='pricing'], [class*='table'], .support-repair-pricing", timeout=10000)
        except:
            print(f"경고: {url}에서 특정 표 구조를 찾지 못했습니다. 전체 텍스트 분석을 시도합니다.")

        # HTML 소스 파싱
        content = await page.content()
        soup = BeautifulSoup(content, 'html.parser')

        # [전략] '모델명'과 '가격'이 포함된 li 또는 div 요소를 찾습니다.
        # 삼성 지원 페이지의 일반적인 구조인 리스트 항목(li)을 탐색합니다.
        items = soup.select("li, tr") # 리스트 형태나 표 형태 모두 탐색
        
        for item in items:
            text = item.get_text(separator=" ", strip=True)
            
            # 간단한 필터링: 'Galaxy' 또는 'Note', 'Fold'가 포함되고 숫자가 있는 줄만 추출
            if any(keyword in text for keyword in ["Galaxy", "Fold", "Flip", "Note", "S24", "S23"]):
                # 통화 기호나 숫자가 포함되어 있는지 확인 (가격 정보 유무)
                if any(char.isdigit() for char in text):
                    data_list.append({
                        "URL": url,
                        "Raw_Data": text
                    })
                    
    except Exception as e:
        print(f"에러 발생 ({url}): {e}")
    finally:
        await page.close()
    
    return data_list

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True) # 창을 보고 싶으면 False로 변경
        
        all_results = []
        for url in urls:
            result = await scrape_samsung_table(browser, url)
            all_results.extend(result)
        
        await browser.close()
        
        # 3. 결과 저장 (Pandas 이용)
        if all_results:
            df = pd.DataFrame(all_results)
            # 엑셀 파일로 저장
            output_file = "samsung_repair_prices.xlsx"
            df.to_excel(output_file, index=False)
            print(f"\n성공: {len(all_results)}개의 데이터를 {output_file}에 저장했습니다.")
        else:
            print("\n수집된 데이터가 없습니다.")

if __name__ == "__main__":
    asyncio.run(main())

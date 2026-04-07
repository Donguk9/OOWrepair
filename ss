import asyncio
from playwright.async_api import async_playwright
from playwright_stealth import stealth_async  # 스텔스 라이브러리 추가
from bs4 import BeautifulSoup
import pandas as pd

urls = ["https://www.samsung.com/us/support/cracked-screen-repair/"]

async def scrape_samsung_table(browser_context, url):
    page = await browser_context.new_page()
    
    # 1. 스텔스 모드 적용 (봇 탐지 방지)
    await stealth_async(page)
    
    data_list = []
    try:
        print(f"접속 시도: {url}")
        
        # 2. 페이지 이동 (timeout을 늘리고 wait_until을 변경)
        # 'domcontentloaded'는 HTML 구조만 로드되면 바로 다음으로 넘어갑니다.
        await page.goto(url, wait_until="domcontentloaded", timeout=60000)
        
        # 3. 페이지 로딩을 위해 잠시 대기 (사람처럼 보이게 함)
        await page.wait_for_timeout(5000) 

        # 표나 리스트가 로드될 때까지 대기
        await page.wait_for_selector("body", timeout=10000)
        
        content = await page.content()
        soup = BeautifulSoup(content, 'html.parser')
        
        # 데이터 추출 로직
        items = soup.select("li, tr, div[class*='pricing']")
        for item in items:
            text = item.get_text(separator=" ", strip=True)
            if any(k in text for k in ["Galaxy", "S24", "S23", "Fold", "Flip"]):
                if "$" in text or any(char.isdigit() for char in text):
                    data_list.append({"URL": url, "Raw_Data": text})
                    
    except Exception as e:
        print(f"상세 에러 내용 ({url}): {e}")
    finally:
        await page.close()
    return data_list

async def main():
    async with async_playwright() as p:
        # 4. 브라우저 설정 강화
        browser = await p.chromium.launch(
            headless=False, # 눈으로 확인하기 위해 우선 False로 설정
            args=["--disable-blink-features=AutomationControlled"] # 자동화 제어 흔적 제거
        )
        
        # 5. 컨텍스트 설정 (User-Agent 포함)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        )
        
        all_results = []
        for url in urls:
            result = await scrape_samsung_table(context, url)
            all_results.extend(result)
            
        await browser.close()
        
        if all_results:
            df = pd.DataFrame(all_results)
            df.to_excel("samsung_repair_prices_fixed.xlsx", index=False)
            print(f"\n성공: {len(all_results)}개의 데이터를 저장했습니다.")
        else:
            print("\n데이터를 찾지 못했습니다. 사이트 구조나 차단 여부를 확인하세요.")

if __name__ == "__main__":
    asyncio.run(main())

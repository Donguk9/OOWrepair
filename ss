import asyncio
from playwright.async_api import async_playwright
import pandas as pd
from bs4 import BeautifulSoup

# 1. 수집할 국가별 링크 리스트 (여기에 50개 추가 가능)
target_urls = [
    "https://www.samsung.com/us/support/cracked-screen-repair/",
]

async def scrape_samsung(browser_context, url):
    page = await browser_context.new_page()
    
    # 봇 탐지 방지를 위한 자바스크립트 주입 (성공했던 설정)
    await page.add_init_script("""
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    """)

    results = []
    try:
        print(f"[{url}] 접속 중...")
        # 페이지 로드 (네트워크가 잠잠해질 때까지 대기)
        await page.goto(url, wait_until="domcontentloaded", timeout=60000)
        
        # 삼성 페이지는 로딩이 느릴 수 있으므로 5초 정도 확실히 대기
        await page.wait_for_timeout(5000) 

        # HTML 소스 가져오기
        content = await page.content()
        soup = BeautifulSoup(content, 'html.parser')

        # [미국 사이트 전용 규칙]
        # 가격 정보는 보통 'support-repair-pricing__list' 클래스 안에 있습니다.
        pricing_sections = soup.select(".support-repair-pricing__list")
        
        if not pricing_sections:
            # 만약 클래스명이 다를 경우를 대비한 백업 (모든 표/리스트 탐색)
            pricing_sections = soup.find_all(['ul', 'table'])

        for section in pricing_sections:
            items = section.find_all(['li', 'tr'])
            for item in items:
                text = item.get_text(separator=" ", strip=True)
                # 가격($)이 포함되고 모델명(Galaxy 등)이 있는 줄만 필터링
                if "$" in text and any(k in text for k in ["Galaxy", "S24", "S23", "Fold", "Flip"]):
                    results.append({
                        "URL": url,
                        "Data": text
                    })
        
        print(f"[{url}] 수집 완료: {len(results)}건")

    except Exception as e:
        print(f"[{url}] 에러 발생: {e}")
    finally:
        await page.close()
    
    return results

async def main():
    async with async_playwright() as p:
        # 실제 사용자처럼 보이도록 컨텍스트 설정
        browser = await p.chromium.launch(headless=False) # 처음엔 눈으로 확인하세요
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        )

        final_data = []
        for url in target_urls:
            data = await scrape_samsung(context, url)
            final_data.extend(data)
            await asyncio.sleep(2) # 국가 간 이동 시 간격 두기

        await browser.close()

        # 2. 엑셀 저장
        if final_data:
            df = pd.DataFrame(final_data)
            # 수집된 데이터를 '모델명'과 '가격'으로 분리하는 로직 (간이 정규식)
            # 예: "Galaxy S24 Ultra $319" -> 모델: Galaxy S24 Ultra, 가격: $319
            df.to_excel("samsung_prices_result.xlsx", index=False)
            print("\n파일 저장 완료: samsung_prices_result.xlsx")
        else:
            print("\n수집된 데이터가 없습니다.")

if __name__ == "__main__":
    asyncio.run(main())

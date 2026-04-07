import asyncio
from playwright.async_api import async_playwright
import pandas as pd
from bs4 import BeautifulSoup
import re

async def scrape_samsung_robust():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False) # 작동 확인을 위해 켬
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        )
        page = await context.new_page()
        
        url = "https://www.samsung.com/us/support/cracked-screen-repair/"
        print(f"접속 중: {url}")
        
        try:
            await page.goto(url, wait_until="domcontentloaded")
            
            # 1. 페이지를 아래로 끝까지 스크롤 (레이지 로딩 대응)
            await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            await page.wait_for_timeout(5000) # 로딩 대기 시간 충분히 확보
            
            # 2. 전체 HTML 가져오기
            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')
            
            # 3. 전략 변경: 특정 클래스가 아니라 '텍스트' 자체를 뒤져서 찾기
            # Galaxy라는 단어가 포함된 모든 태그를 찾습니다.
            results = []
            # 'div', 'li', 'tr', 'p' 태그 중 텍스트가 있는 것들 탐색
            potential_elements = soup.find_all(['div', 'li', 'tr', 'p', 'span'])
            
            for element in potential_elements:
                # 자식 태그 없이 본인에게만 텍스트가 있는 경우 위주로 수집 (중복 방지)
                if element.find(recursive=False) is None: 
                    text = element.get_text(strip=True)
                    
                    # 'Galaxy'가 있고 숫자(가격)가 포함된 줄만 필터링
                    if "Galaxy" in text and "$" in text:
                        # 정규표현식으로 모델명과 가격 대략 분리
                        # 예: Galaxy S24 Ultra $319 -> [Galaxy S24 Ultra, $319]
                        match = re.search(r"(Galaxy.*?)\s*(\$[\d,.]+)", text)
                        if match:
                            results.append({
                                "Model": match.group(1),
                                "Price": match.group(2)
                            })
                        else:
                            # 패턴에 안 맞아도 일단 생으로 저장
                            results.append({"Raw_Data": text})

            # 중복 제거 및 저장
            if results:
                df = pd.DataFrame(results).drop_duplicates()
                df.to_excel("samsung_us_prices.xlsx", index=False)
                print(f"성공! {len(df)}건의 데이터를 추출했습니다.")
            else:
                print("여전히 데이터를 찾지 못했습니다. 브라우저 창에서 가격표가 실제로 보이는지 확인해 주세요.")

        except Exception as e:
            print(f"에러 발생: {e}")
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(scrape_samsung_robust())

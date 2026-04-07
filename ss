import asyncio
from playwright.async_api import async_playwright
import pandas as pd
from bs4 import BeautifulSoup

async def run_scraper():
    async with async_playwright() as p:
        # 1. 브라우저 실행 옵션 강화
        # 'Persistent Context'를 사용하면 실제 사용자가 쓰는 것과 유사한 환경을 만듭니다.
        user_data_dir = "./user_data" # 임시 사용자 데이터를 저장할 폴더
        
        browser_context = await p.chromium.launch_persistent_context(
            user_data_dir,
            headless=False, # 눈으로 확인하기 위해 켭니다. 성공하면 True로 바꾸세요.
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-setuid-sandbox"
            ],
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        )

        page = browser_context.pages[0] # 첫 번째 페이지 사용

        # 2. 웹드라이버 흔적 지우기 (자바스크립트 주입)
        await page.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            });
        """)

        url = "https://www.samsung.com/us/support/cracked-screen-repair/"
        
        try:
            print(f"접속 시도 중... {url}")
            # 'networkidle' 대신 'commit'을 써서 서버가 연결을 끊기 전에 일단 진입 시도
            await page.goto(url, wait_until="commit", timeout=60000)
            
            # 페이지가 뜰 때까지 조금 기다림 (사람처럼 행동)
            await page.wait_for_timeout(7000) 

            # 화면에 특정 텍스트가 나올 때까지 대기
            await page.wait_for_selector("body")
            
            print("페이지 로드 성공! 데이터를 읽어옵니다.")

            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')
            
            # 데이터 추출 (미국 사이트 특화)
            data_list = []
            # 'Galaxy' 단어가 들어간 행(tr)이나 리스트(li)를 모두 찾음
            items = soup.find_all(['tr', 'li', 'div'], string=lambda s: s and "Galaxy" in s)

            for item in items:
                text = item.get_text(separator=" ", strip=True)
                if "$" in text:
                    data_list.append({"Data": text})

            if data_list:
                df = pd.DataFrame(data_list)
                df.to_excel("samsung_repair_final.xlsx", index=False)
                print(f"성공: {len(data_list)}건의 데이터를 엑셀로 저장했습니다.")
            else:
                print("데이터를 찾지 못했습니다. 선택자(Selector)를 조정해야 할 수도 있습니다.")

        except Exception as e:
            print(f"에러 발생: {e}")
        
        finally:
            await browser_context.close()

if __name__ == "__main__":
    asyncio.run(run_scraper())

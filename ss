import requests
import os
from bs4 import BeautifulSoup
import urllib3
import pandas as pd
import numpy as np
import re

# SSL 경고 off, 프록시 설정
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

os.environ['HTTP_PROXY'] = 'http://168.219.61.252:8080'
os.environ['HTTPS_PROXY'] = 'http://168.219.61.252:8080'
os.environ['NO_PROXY'] = 'localhost,127.0.0.1,.sec.samsung.net'

# Exchange Rate
rate_df = pd.read_excel("exchange_rate.xlsx")

# 가격 clean 로직
def clean_price(price):
    if pd.isna(price):
        return np.nan
    price = price.strip()
    if price == "-":
        return np.nan
    if "|" in price:
        price = price.split("|")[1].strip()
    price = re.sub(r"[^\d.]","",price)
    
    try:
        return float(price)
    except:
        return np.nan()

# 1. 미국
url = "https://www.samsung.com/us/support/cracked-screen-repair/"
html_doc = requests.get(url).text
html_doc
subs = 'SEA'

soup = BeautifulSoup(html_doc, 'html.parser')
tables = soup.find_all('table')

all_data = []
for table in tables:
    # 테이블 제목 찾기
    header_cell = table.find(["th","td"], class_ = "sub_table_header")
    if header_cell:
        table_title = header_cell.get_text(strip=True) 
    else:
        first_row = table.find("tr")
        table_title = first_row.get_text(strip=True) if first_row else "Unknown"

    current_category = None

    rows = table.find_all('tr')

    for row in rows:
        if row.find(["td","th"], class_ = "sub_table_header"): continue
        cols = row.find_all(["td","th"])
        cols = [col.get_text(strip=True) for col in cols]

        if len(cols)==3:
            current_category = cols[0]
            model = cols[1]
            price = cols[2]
        
        elif len(cols)==2:
            model = cols[0]
            price = cols[1]     

        else : continue

        all_data.append([
            subs,
            table_title,
            current_category,
            model,
            price,
            url])

df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Category", "Model", "Price", "URL"])
df["Price"] = df["Price"].apply(clean_price)
df = df.merge(rate_df, on="Subsidiary", how = "left")
df["Price_USD"]= df["Price"] / df["Exchange"]
print(df)

df.to_excel("result.xlsx", index=False)
# print(rate_df)

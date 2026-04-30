import requests
import os
from bs4 import BeautifulSoup
import urllib3
import pandas as pd
import numpy as np
import re
import json
import ast
from datetime import datetime

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
    if price in ["-", "n/a", "null", "", "#VALOR!"]: return np.nan

    if "|" in price: # 할인가
        price = price.split("|")[1].strip()
    price = re.sub(r"[^\d.]","",price)
    
    try:
        return float(price)
    except:
        return np.nan()
    
# 컬럼 키워드 정의
column_keywords = {
    "model": ["model", "device", "product"],
    "series": ["series", "category"],
    "repair_price": ["repair"],
    "module_price": ["module"],
    "price": ["price", "cost", "fee"]
}

# 컬럼 맵핑
def get_column_map(header_cells):
    col_map = {}
    for idx, cell in enumerate(header_cells):
        text = cell.get_text(strip=True).lower()
        for key, keywords in column_keywords.items():
            if any(k in text for k in keywords):
                col_map[key] = idx
    return col_map


# ------------------- 기준 --------------------
# 1. Series : Galaxy Note, Galaxy S, Galaxy Z
# 2. Model : 이름에 "Galaxy" 들어가면 제거

# 법인별 로직
def sea():
    url = "https://www.samsung.com/us/support/cracked-screen-repair/"
    html_doc = requests.get(url, verify = False).text
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

    df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    df["Price"] = df["Price"].apply(clean_price)
    df = df.merge(rate_df, on="Subsidiary", how = "left")
    df["Price_USD"]= df["Price"] / df["Exchange"]
    print(df)
    return df
def seca():
    
    url = "https://www.samsung.com/ca/support/Out-of-Warranty-Pricing/"
    html_doc = requests.get(url, verify = False).text
    subs = 'SECA'
    soup = BeautifulSoup(html_doc, 'html.parser')
    tables = soup.find_all('table')

    all_data = []
    for table in tables:

        first_cells = [row.find(["th", "td"]) for row in table.find_all("tr")]

        current_series = None
        for cell in first_cells:
            if cell and cell.get_text(strip=True):
                current_series = cell.get_text(strip=True)
                break

        rows = table.find_all('tr')[1:]
        for row in rows:
            # if row.find(["td","th"], class_ = "sub_table_header"): continue
            cols = row.find_all(["td","th"])
            cols = [col.get_text(strip=True) for col in cols]

            if len(cols)==4:
                model, repair_price, module_price = cols[1], cols[2], cols[3]
                all_data.append([subs,"Screen Repair",current_series,model,repair_price,url])
                all_data.append([subs,"Module Replacement",current_series,model,module_price,url])            
            
            elif len(cols)==3:
                # current_series = cols[0]
                model = cols[0]
                repair_price = cols[1]  
                all_data.append([subs,"Screen Repair",current_series,model,repair_price,url])   

            else : continue

    df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    df["Price"] = df["Price"].apply(clean_price)
    df = df.merge(rate_df, on="Subsidiary", how = "left")
    df["Price_USD"]= df["Price"] / df["Exchange"]
    print(df)
    return df
def seda():
    url = "https://www.samsung.com/br/support/valorreparo/"
    html_doc = requests.get(url, verify = False).text
    subs = "SEDA"

    def clean_price_br(price):
        if pd.isna(price):
            return np.nan
        price = price.strip()
        if price == "-":
            return np.nan
        if "|" in price:
            price = price.split("|")[1].strip()
        price = re.sub(r"[^\d,.]","",price)
        if ',' in price:
            price = price.replace('.','')
            price = price.replace(',', '.')
        
        try:
            return float(price)
        except:
            return np.nan()

    start_pattern = re.search(r'var\s+items\s*=\s*\[', html_doc)

    if start_pattern:
        start_index = start_pattern.start()
        content_start = html_doc.find('[', start_index)
        bracket_count = 0
        end_index = -1
        for i in range(content_start, len(html_doc)):
            if html_doc[i] == '[':
                bracket_count +=1
            elif html_doc[i] == ']':
                bracket_count -= 1
            if bracket_count == 0:
                end_index = i + 1
                break
        
        if end_index != -1:
            raw_json_str = html_doc[content_start:end_index]
            try:
                fixed_json_str = re.sub(r'([{,]\s*)([a-zA-Z0-9_]+)\s*:', r'\1"\2":', raw_json_str)
                data_list = json.loads(fixed_json_str)
                df = pd.DataFrame(data_list)
                print(f"추출 성공! 총 {len(df)}개의 모델 데이터를 찾았습니다.")
            except Exception as e:
                print("JSON 파싱 중 오류가 발생했습니다.")
        else:
            print("닫는 괄호를 찾지 못했습니다.")
    else: 
        print("소스 코드에서 'var items' 변수를 찾지 못했습니다.")

    final_df = pd.DataFrame(columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    final_df['Repair Type'] = df['damageDescription']
    final_df['Model'] = df['modelName']
    final_df['Price'] = df['repairCost'].apply(clean_price_br)
    final_df['URL'] = url
    final_df['Subsidiary'] = subs

    final_df = final_df.merge(rate_df, on="Subsidiary", how = "left")
    final_df["Price_USD"]= final_df["Price"] / final_df["Exchange"]
    print(final_df)
    return final_df

def sem():
    url = "https://www.samsung.com/mx/support/price-list/"
    html_doc = requests.get(url, verify = False).text
    subs = "SEM"

    def clean_price_mx(price):
        if pd.isna(price):
            return np.nan
        if isinstance(price, (int, float)):
            return float(price)

        price = str(price).strip()
        if price in ["-", "n/a", "null", "", "#VALOR!"]: return np.nan
        if "|" in price:
            price = price.split("|")[1].strip()

        price = re.sub(r"[^\d,.]","",price)
        if ',' in price:
            price = price.replace('.','')
            price = price.replace(',', '.')
        
        try:
            return float(price)
        except:
            return np.nan

    start_pattern = re.search(r'var\s+obj\s*=\s*\[', html_doc)

    if start_pattern:
        start_index = start_pattern.start()
        content_start = html_doc.find('[', start_index)
        bracket_count = 0
        end_index = -1
        for i in range(content_start, len(html_doc)):
            if html_doc[i] == '[':
                bracket_count +=1
            elif html_doc[i] == ']':
                bracket_count -= 1
            if bracket_count == 0:
                end_index = i + 1
                break
        
        if end_index != -1:
            raw_json_str = html_doc[content_start:end_index]
            try:
                fixed_json_str = re.sub(r'([{,]\s*)([a-zA-Z0-9_]+)\s*:', r'\1"\2":', raw_json_str)
                data_list = json.loads(fixed_json_str)
                df = pd.DataFrame(data_list)
                print(f"추출 성공! 총 {len(df)}개의 모델 데이터를 찾았습니다.")
            except Exception as e:
                print("JSON 파싱 중 오류가 발생했습니다.")
        else:
            print("닫는 괄호를 찾지 못했습니다.")
    else: 
        print("소스 코드에서 'var items' 변수를 찾지 못했습니다.")

    final_df = pd.DataFrame(columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    final_df['Repair Type'] = df['reparacion']
    final_df['Model'] = df['display_name']
    final_df['Price'] = df['precio'].apply(clean_price_mx)
    final_df['URL'] = url
    final_df['Subsidiary'] = subs

    final_df = final_df.merge(rate_df, on="Subsidiary", how = "left")
    final_df["Price_USD"]= final_df["Price"] / final_df["Exchange"]
    print(final_df)
    return final_df

def samcol():
    url = "https://www.samsung.com/co/campaign/cost-and-spares/"
    html_doc = requests.get(url, verify = False).text
    subs = "SAMCOL"

    pattern = re.compile(r'var\s+obj\s*=\s\[(.*?)\]', re.DOTALL)
    match = pattern.search(html_doc)

    if match:
        items_str = match.group(1).strip()

        try:
            data_list = ast.literal_eval(f"[{items_str}]")
            for item in data_list:
                print(f"모델명: {item['modelName']}, 가격: {item.get('price', '정보없음')}")

        except Exception as e:
            print(f"파싱 에러: {e}")

    df = pd.DataFrame(data_list)
    # print(df.head())
    final_df = pd.DataFrame(columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    final_df['Repair Type'] = df['reparacion']
    final_df['Model'] = df['display_name'].str.split(' ').str[0]
    final_df['Price'] = df['precio'].apply(clean_price)
    final_df['URL'] = url
    final_df['Subsidiary'] = subs

    final_df = final_df.merge(rate_df, on="Subsidiary", how = "left")
    final_df["Price_USD"]= final_df["Price"] / final_df["Exchange"]
    print(final_df)
    return final_df

def sep():
    url = "https://www.samsung.com/pt/support/reparacoes-fora-de-garantia/"
    html_doc = requests.get(url, verify = False).text
    subs = 'SEP'
    soup = BeautifulSoup(html_doc, 'html.parser')
    tables = soup.find_all('table')

    all_data = []
    for table in tables:
        header_row = table.find('tr')
        header_names = [th.get_text(strip=True).lower() for th in header_row.find_all(["th", "td"])]
        header_search = [name.lower() for name in header_names]

        # "Screen Repair" 위치 찾기
        screen_index = -1
        repair_type_name = "Other Repair"

        for i, col_text in enumerate(header_search):
            if "reparação do ecrã" in col_text:
                screen_index = i
                repair_type_name = header_names[i]
                break

        rows = table.find_all('tr')[1:]
        for row in rows:
            cols = [col.get_text(strip=True) for col in row.find_all(["td", "th"])]
            model = cols[0]

            if screen_index != -1:
                repair_price = cols[screen_index]
                all_data.append([subs,"Screen Repair","",model,repair_price,url])
            else:
                repair_price = cols[1]
                fallback_name = header_names[1] if len(header_names) > 1 else "Repair"
                all_data.append([subs,fallback_name,"",model,repair_price,url])

    df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    df["Price"] = df["Price"].apply(clean_price)
    df = df.merge(rate_df, on="Subsidiary", how = "left")
    df["Price_USD"]= df["Price"] / df["Exchange"]
    print(df)
    return df

def sena():
    url = "https://www.samsung.com/se/support/smart-service-repair/"
    html_doc = requests.get(url, verify = False).text
    subs = 'SENA'
    soup = BeautifulSoup(html_doc, 'html.parser')
    tables = soup.find_all('table')

    all_data = []
    for table in tables:
        header_row = table.find('tr')
        header_names = [th.get_text(strip=True).lower() for th in header_row.find_all(["th", "td"])]
        header_search = [name.lower() for name in header_names]

        # "Screen Repair" 위치 찾기
        screen_index = -1
        repair_type_name = "Other Repair"

        for i, col_text in enumerate(header_search):
            if "byte display" in col_text:
                screen_index = i
                repair_type_name = header_names[i]
                break

        rows = table.find_all('tr')[1:]
        for row in rows:
            cols = [col.get_text(strip=True) for col in row.find_all(["td", "th"])]
            model = cols[0]

            if screen_index != -1:
                repair_price = cols[screen_index]
                all_data.append([subs,"Screen Repair","",model,repair_price,url])
            else:
                repair_price = cols[1]
                fallback_name = header_names[1] if len(header_names) > 1 else "Repair"
                all_data.append([subs,fallback_name,"",model,repair_price,url])

    df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    df["Price"] = df["Price"].apply(clean_price)
    df = df.merge(rate_df, on="Subsidiary", how = "left")
    df["Price_USD"]= df["Price"] / df["Exchange"]
    print(df)
    return df

def sesg():
    url = "https://www.samsung.com/ch/support/mobile-devices/display-reparaturkosten/"
    html_doc = requests.get(url, verify = False).text
    subs = 'SESG'
    soup = BeautifulSoup(html_doc, 'html.parser')
    tables = soup.find_all('table')

    all_data = []
    for table in tables:
        header_row = table.find('tr')
        h_cols = [th.get_text(strip=True).lower() for th in header_row.find_all(["th","td"])]

        # "Screen Repair" 위치 찾기
        screen_index = -1
        module_index = -1
        inner_index = -1
        outer_index = -1

        for i, text in enumerate(h_cols):
            if "ohne rahmen" in text:
                screen_index = i
            elif "displayreparatur" in text:
                module_index = i
            elif "innendisplay" in text:
                inner_index = i
            elif "frontdisplay" in text:
                outer_index = i

        rows = table.find_all('tr')[1:]
        for row in rows:
            cols = [col.get_text(strip=True) for col in row.find_all(["td", "th"])]

            if len(cols) < 2:
                continue

            model = cols[0]

            if screen_index != -1 and len(cols) > screen_index :
                repair_price = cols[screen_index]
                all_data.append([subs,"Screen Repair","",model,repair_price,url])
            if module_index != -1 and len(cols) > screen_index:
                repair_price = cols[module_index]
                all_data.append([subs,"Module Replacement","",model,repair_price,url])      
            if inner_index != -1 and len(cols) > screen_index:
                repair_price = cols[inner_index]
                all_data.append([subs,"Inner Screen","",model,repair_price,url])
            if outer_index != -1 and len(cols) > screen_index:
                repair_price = cols[outer_index]
                all_data.append([subs,"Outer Screen","",model,repair_price,url])    

    df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    df["Price"] = df["Price"].apply(clean_price)
    df = df.merge(rate_df, on="Subsidiary", how = "left")
    df["Price_USD"]= df["Price"] / df["Exchange"]
    print(df)
    return df

def sela():
    url = "https://www.samsung.com/latin/support/PreciosOWPanama/"
    html_doc = requests.get(url, verify = False).text
    subs = "SELA"

    pattern = re.compile(r'items:\s*\[(.*?)\]', re.DOTALL)
    match = pattern.search(html_doc)

    if match:
        items_str = match.group(1).strip()

        try:
            data_list = ast.literal_eval(f"[{items_str}]")
            for item in data_list:
                print(f"모델명: {item['modelName']}, 가격: {item.get('price', '정보없음')}")

        except Exception as e:
            print(f"파싱 에러: {e}")

    df = pd.DataFrame(data_list)
    print(df.head())
    final_df = pd.DataFrame(columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    final_df['Repair Type'] = df['damageDescription']
    final_df['Model'] = df['modelCode'].str.split(' ').str[0]
    final_df['Price'] = df['repairCost'].apply(clean_price)
    final_df['URL'] = url
    final_df['Subsidiary'] = subs

    final_df = final_df.merge(rate_df, on="Subsidiary", how = "left")
    final_df["Price_USD"]= final_df["Price"] / final_df["Exchange"]
    # print(final_df)
    return final_df

def sena():
    url = "https://www.samsung.com/se/support/smart-service-repair/"
    html_doc = requests.get(url, verify = False).text
    subs = 'SENA'
    soup = BeautifulSoup(html_doc, 'html.parser')
    tables = soup.find_all('table')

    all_data = []
    for table in tables:
        header_row = table.find('tr')
        header_names = [th.get_text(strip=True).lower() for th in header_row.find_all(["th", "td"])]
        header_search = [name.lower() for name in header_names]

        # "Screen Repair" 위치 찾기
        screen_index = -1
        repair_type_name = "Other Repair"

        for i, col_text in enumerate(header_search):
            if "byte display" in col_text:
                screen_index = i
                repair_type_name = header_names[i]
                break

        rows = table.find_all('tr')[1:]
        for row in rows:
            cols = [col.get_text(strip=True) for col in row.find_all(["td", "th"])]
            model = cols[0]

            if screen_index != -1:
                repair_price = cols[screen_index]
                all_data.append([subs,"Screen Repair",model,model,repair_price,url])
            else:
                repair_price = cols[1]
                fallback_name = header_names[1] if len(header_names) > 1 else "Repair"
                all_data.append([subs,fallback_name,model,model,repair_price,url])

    df = pd.DataFrame(all_data, columns=["Subsidiary", "Repair Type", "Series", "Model", "Price", "URL"])
    df["Price"] = df["Price"].apply(clean_price)
    df = df.merge(rate_df, on="Subsidiary", how = "left")
    df["Price_USD"]= df["Price"] / df["Exchange"]
    print(df)
    return df

# 실행
df_us = sea()
df_ca = seca()
df_br = seda()
df_mx = sem()
df_co = samcol()
df_pt = sep()
df_se = sena()
df_sg = sesg()
df_pa = sela()

final_df = pd.concat([df_us, df_ca, df_br, df_mx, df_co, df_pa, df_pt, df_se, df_sg], ignore_index=True)

#후처리
def model_clean(name):
    name = str(name)
    if "(" in name or ")" not in name:
        start = name.find('(') + 1
        end = name.find(')')
        if 'sm-' in name[start:end].strip().lower() : return name[:start-1].strip()
        elif 'sm-' in name[:start-1].strip().lower(): return name[start:end].strip()
    return name.strip()

final_df['Model'] = final_df['Model'].str.replace('Galaxy', '', case=False).str.strip()
final_df['Model'] = final_df['Model'].apply(model_clean)

series_map = {"Galaxy Series": "Galaxy S"}
final_df['Series'] = final_df['Series'].replace(series_map)

is_empty = final_df['Series'].isnull() | (final_df['Series'] == "")
final_df.loc[is_empty & final_df['Model'].str.lower().str.startswith('s'), 'Series'] = "Galaxy S"
final_df.loc[is_empty & final_df['Model'].str.lower().str.startswith('a'), 'Series'] = "Galaxy A"
final_df.loc[is_empty & final_df['Model'].str.lower().str.startswith('m'), 'Series'] = "Galaxy M"
final_df.loc[is_empty & final_df['Model'].str.lower().str.startswith('note'), 'Series'] = "Galaxy Note"
final_df.loc[is_empty & final_df['Model'].str.lower().str.startswith('z f'), 'Series'] = "Galaxy Z"
final_df['Series'] = final_df['Series'].fillna('Others').replace('', 'Others')

today_date = datetime.now().strftime("%Y%m%d")
final_df.to_excel(f"result_{today_date}.xlsx", index=False)

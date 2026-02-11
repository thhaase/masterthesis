import pandas as pd
import urllib.parse

from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
import time


data_path = "/home/thhaase/Documents/synosys_masterthesis"

p = pd.read_parquet(f"{data_path}/politicians.parquet.gzip")

p_missing_x = p.loc[p['x_url'].isna(), ['politician_name', 'x_url']]

print(p_missing_x['politician_name'])

names = [name.replace(" ", "+") for name in p_missing_x["politician_name"]]

urls = [f'https://www.google.com/search?q="{n}"+site:x.com' for n in names]
urls = [f"https://duckduckgo.com/?q=~%22{n}%22+site%3Ax.com&ia=web" for n in names]

options = Options()
#options.add_argument('--headless=new') 
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

service = ChromeService(ChromeDriverManager().install())
wd = webdriver.Chrome(service=service, options=options)

results_data = []

try:
    for url in urls:
        print(f"Scraping: {url}")
        wd.get(url)
        time.sleep(4) # explicit waits would be more robust, but sleep works for simple cases

        elements = wd.find_elements(By.XPATH, "//a[@data-testid='result-title-a']")
        
        page_links = []
        for el in elements:
            href = el.get_attribute("href")
            if href and ("x.com" in href or "twitter.com" in href):
                page_links.append(href)
            
            if len(page_links) >= 5:
                break
        page_links += [None] * (5 - len(page_links))
        results_data.append([url] + page_links)

finally:
    wd.quit()

# Create DataFrame
columns = ['query', 'result_1', 'result_2', 'result_3', 'result_4', 'result_5']
df = pd.DataFrame(results_data, columns=columns)

print(df)

df.to_csv(f"{data_path}/politicians_enrichment_duckduckgo.csv", index=False)


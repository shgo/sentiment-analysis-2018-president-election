import logging
import time
from selenium import webdriver


class InstagramClient:

    def __init__(self, names=None, np_posts=5, np_comments=10):
        self.names = names
        self.np_posts = np_posts
        self.np_comments = np_comments
        self.results = []

    def start(self):
        for name in self.names:
            driver = webdriver.Firefox()
            driver.get(f"https://www.instagram.com/{name}/?hl=pt-br")

            for _ in range(self.np_posts):
                # for _ in range(scroll):
                driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
                time.sleep(1)

            feeds = []
            links = driver.find_elements_by_tag_name('a')
            for link in links:
                href = link.get_attribute('href')
                if f'taken-by={name}' in href:
                    feeds.append(href)

            data = {
                'name': name,
                'feed_views_likes': 0,
                'comments': []
            }

            for feed in feeds:
                driver.get(feed)

                like = driver.find_element_by_xpath(
                    "/html/body/span/section/main/div/div/article/div[2]/section[2]/div/span/span")
                data['feed_views_likes'] = int((like.text).replace(',', ''))

                try:
                    btn = driver.find_element_by_xpath("//button[contains(text(),'Load more comments')]")
                    for _ in range(self.np_comments):
                        btn.click()
                        time.sleep(.5)
                except Exception as e:
                    logging.info(f'ERROR: No button to load more comments : {e}')

                try:
                    comments = driver.find_elements_by_xpath('//ul/li/div/div/div/span')
                    for comment in comments:
                        data['comments'].append(comment.text)
                except Exception as e:
                    logging.info(f'ERROR: No Comments found : {e}')

            self.results.append(data)
            driver.close()
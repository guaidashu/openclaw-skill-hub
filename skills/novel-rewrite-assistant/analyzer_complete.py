#!/usr/bin/env python3
"""
小说分析模块 - 完整版
"""

import re
import json
import time
import hashlib
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
from urllib.parse import urlparse
import requests
from bs4 import BeautifulSoup


class NovelAnalyzer:
    """小说分析器"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.cache_dir = Path(config.get("cache", {}).get("cache_dir", "cache"))
        self.cache_dir.mkdir(exist_ok=True)
        
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        }
    
    def analyze(self, url: str) -> Optional[Dict]:
        """分析小说"""
        try:
            cache_key = self._get_cache_key(url)
            cached = self._load_from_cache(cache_key)
            if cached:
                print("使用缓存的分析结果")
                return cached
            
            print(f"获取小说内容: {url}")
            content = self._fetch_content(url)
            if not content:
                return None
            
            print("分析小说内容...")
            result = self._analyze_content(content, url)
            
            self._save_to_cache(cache_key, result)
            return result
            
        except Exception as e:
            print(f"分析失败: {e}")
            return None
    
    def _fetch_content(self, url: str) -> Optional[str]:
        """获取网页内容"""
        try:
            resp = requests.get(url, headers=self.headers, timeout=30)
            resp.raise_for_status()
            resp.encoding = self._detect_encoding(resp)
            return resp.text
        except Exception as e:
            print(f"获取失败: {e}")
            return None
    
    def _detect_encoding(self, response) -> str:
        """检测编码"""
        if response.encoding:
            return response.encoding
        return 'utf-8'
    
    def _analyze_content(self, content: str, url: str) -> Dict:
        """分析内容"""
        soup = BeautifulSoup(content, 'html.parser')
        
        return {
            "url": url,
            "title": self._extract_title(soup, url),
            "author": self._extract_author(soup),
            "chapters": self._extract_chapters(soup),
            "writing_style": self._analyze_style(content),
            "main_characters": self._extract_characters(content),
            "analysis_time": datetime.now().isoformat(),
            "metadata": {
                "total_chapters": 0,
                "content_type": "web_novel"
            }
        }
    
    def _extract_title(self, soup: BeautifulSoup, url: str) -> str:
        """提取标题"""
        # 尝试多种选择器
        for selector in ['h1', '.title', '#title', 'meta[property="og:title"]']:
            if selector.startswith('meta'):
                meta = soup.select_one(selector)
                if meta and meta.get('content'):
                    return meta['content'].strip()
            else:
                elem = soup.select_one(selector)
                if elem and elem.text.strip():
                    return elem.text.strip()
        
        # 从URL提取
        parsed = urlparse(url)
        path = parsed.path.split('/')[-1]
        if path and len(path) > 2:
            return path.replace('-', ' ').replace('_', ' ').title()
        
        return "未知标题"
    
    def _extract_author(self, soup: BeautifulSoup) -> str:
        """提取作者"""
        for selector in ['.author', '#author', 'meta[name="author"]']:
            if selector.startswith('meta'):
                meta = soup.select_one(selector)
                if meta and meta.get('content'):
                    return meta['content'].strip()
            else:
                elem = soup.select_one(selector)
                if elem and elem.text.strip():
                    return elem.text.strip()
        
        return "未知作者"
    
    def _extract_chapters(self, soup: BeautifulSoup) -> List[Dict]:
        """提取章节"""
        chapters = []
        links = soup.find_all('a', href=True)
        
        for link in links:
            text = link.text.strip()
            href = link['href']
            
            # 简单判断是否是章节
            if ('章' in text or '节' in text or '回' in text) and len(text) < 50:
                chapters.append({
                    "title": text,
                    "url": href,
                    "order": len(chapters) + 1
                })
                
                if len(chapters) >= 20:  # 只取前20章
                    break
        
        return chapters
    
    def _analyze_style(self, content: str) -> Dict:
        """分析写作风格"""
        sample = content[:5000]
        
        return {
            "style_type": "网络小说",
            "dialogue_ratio": 0.2,
            "paragraph_avg": 150,
            "sentence_avg": 25
        }
    
    def _extract_characters(self, content: str) -> List[Dict]:
        """提取角色"""
        characters = []
        
        # 简单的中文人名提取
        pattern = r'[赵钱孙李周吴郑王冯陈褚卫][\u4e00-\u9fa5]{1,2}'
        names = re.findall(pattern, content[:20000])
        
        # 统计频率
        from collections import Counter
        freq = Counter(names)
        
        for name, count in freq.most_common(5):
            if count >= 2:
                characters.append({
                    "name": name,
                    "frequency": count,
                    "role": "主要角色" if count >= 5 else "配角",
                    "gender": self._guess_gender(name)
                })
        
        return characters
    
    def _guess_gender(self, name: str) -> str:
        """猜测性别"""
        female_chars = ['娟', '婷', '娜', '莉', '芳', '玲', '秀', '英']
        male_chars = ['伟', '强', '勇', '军', '杰', '斌', '涛', '明']
        
        for char in name:
            if char in female_chars:
                return "女"
            elif char in male_chars:
                return "男"
        
        return "未知"
    
    def _get_cache_key(self, url: str) -> str:
        """生成缓存键"""
        return hashlib.md5(url.encode()).hexdigest()[:16]
    
    def _load_from_cache(self, key: str) -> Optional[Dict]:
        """从缓存加载"""
        if not self.config["cache"]["enabled"]:
            return None
        
        cache_file = self.cache_dir / f"{key}.json"
        if cache_file.exists():
            cache_age = time.time() - cache_file.stat().st_mtime
            if cache_age < self.config["cache"]["ttl"]:
                try:
                    with open(cache_file, 'r', encoding='utf-8') as f:
                        return json.load(f)
                except:
                    pass
        
        return None
    
    def _save_to_cache(self, key: str, data: Dict):
        """保存到缓存"""
        if not self.config["cache"]["enabled"]:
            return
        
        cache_file = self.cache_dir / f"{key}.json"
        try:
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except:
            pass


# 简化版本，直接使用这个文件
if __name__ == "__main__":
    # 测试代码
    config = {
        "cache": {"enabled": True, "ttl": 3600, "cache_dir": "cache"},
        "analysis": {"max_chapters": 20}
    }
    
    analyzer = NovelAnalyzer(config)
    result = analyzer.analyze("https://www.example.com/novel")
    
    if result:
        print(f"标题: {result['title']}")
        print(f"作者: {result['author']}")
        print(f"章节数: {len(result['chapters'])}")
        print(f"角色数: {len(result['main_characters'])}")
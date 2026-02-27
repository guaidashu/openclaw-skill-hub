#!/usr/bin/env python3
"""
小说分析模块
从URL抓取小说内容并进行分析
"""

import re
import json
import time
import random
from typing import Dict, List, Optional, Tuple
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
        
        # 请求头
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
        
    def analyze(self, url: str) -> Optional[Dict]:
        """分析小说"""
        try:
            # 检查缓存
            cache_key = self._get_cache_key(url)
            cached_result = self._load_from_cache(cache_key)
            if cached_result:
                print("使用缓存的分析结果")
                return cached_result
            
            # 获取小说内容
            print(f"获取小说内容: {url}")
            content = self._fetch_novel_content(url)
            if not content:
                print("错误: 无法获取小说内容")
                return None
            
            # 分析内容
            print("分析小说内容...")
            analysis_result = self._analyze_content(content, url)
            
            # 保存到缓存
            self._save_to_cache(cache_key, analysis_result)
            
            return analysis_result
            
        except Exception as e:
            print(f"分析过程中出错: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def _fetch_novel_content(self, url: str) -> Optional[str]:
        """获取小说内容"""
        try:
            response = requests.get(
                url, 
                headers=self.headers,
                timeout=self.config["analysis"].get("timeout", 30)
            )
            response.raise_for_status()
            response.encoding = self._detect_encoding(response)
            return response.text
        except Exception as e:
            print(f"获取内容失败: {e}")
            return None
    
    def _detect_encoding(self, response) -> str:
        """检测编码"""
        # 尝试从headers中获取
        if response.encoding:
            return response.encoding
        
        # 尝试从content中检测
        try:
            import chardet
            encoding = chardet.detect(response.content)['encoding']
            if encoding:
                return encoding
        except:
            pass
        
        # 默认使用utf-8
        return 'utf-8'
    
    def _analyze_content(self, content: str, url: str) -> Dict:
        """分析小说内容"""
        soup = BeautifulSoup(content, 'html.parser')
        
        # 提取基本信息
        title = self._extract_title(soup, url)
        author = self._extract_author(soup)
        
        # 提取章节
        chapters = self._extract_chapters(soup, content)
        
        # 分析写作风格
        writing_style = self._analyze_writing_style(content, chapters)
        
        # 提取角色
        main_characters = self._extract_characters(content, chapters)
        
        # 分析情节结构
        plot_structure = self._analyze_plot_structure(chapters)
        
        # 构建结果
        result = {
            "url": url,
            "title": title,
            "author": author,
            "chapters": chapters,
            "writing_style": writing_style,
            "main_characters": main_characters,
            "plot_structure": plot_structure,
            "analysis_time": datetime.now().isoformat(),
            "metadata": {
                "total_chapters": len(chapters),
                "avg_chapter_length": self._calculate_avg_length(chapters),
                "content_type": self._detect_content_type(content)
            }
        }
        
        return result
    
    def _extract_title(self, soup: BeautifulSoup, url: str) -> str:
        """提取标题"""
        # 尝试多种选择器
        selectors = [
            'h1', 'h2', '.title', '.book-title', '#title', 
            'meta[property="og:title"]', 'meta[name="title"]'
        ]
        
        for selector in selectors:
            if selector.startswith('meta'):
                meta = soup.select_one(selector)
                if meta and meta.get('content'):
                    return meta['content'].strip()
            else:
                element = soup.select_one(selector)
                if element and element.text.strip():
                    return element.text.strip()
        
        # 从URL中提取
        parsed_url = urlparse(url)
        path_parts = parsed_url.path.split('/')
        for part in reversed(path_parts):
            if part and len(part) > 2:
                return part.replace('-', ' ').replace('_', ' ').title()
        
        return "未知标题"
    
    def _extract_author(self, soup: BeautifulSoup) -> str:
        """提取作者"""
        selectors = [
            '.author', '.writer', '#author', 'meta[name="author"]',
            'meta[property="book:author"]', 'a[href*="author"]'
        ]
        
        for selector in selectors:
            if selector.startswith('meta'):
                meta = soup.select_one(selector)
                if meta and meta.get('content'):
                    return meta['content'].strip()
            else:
                element = soup.select_one(selector)
                if element and element.text.strip():
                    return element.text.strip()
        
        return "未知作者"
    
    def _extract_chapters(self, soup: BeautifulSoup, content: str) -> List[Dict]:
        """提取章节"""
        chapters = []
        
        # 尝试查找章节链接
        chapter_links = soup.find_all('a', href=True)
        
        for link in chapter_links:
            link_text = link.text.strip()
            link_href = link['href']
            
            # 判断是否是章节链接
            if self._is_chapter_link(link_text, link_href):
                chapter = {
                    "title": link_text,
                    "url": link_href,
                    "order": len(chapters) + 1
                }
                chapters.append(chapter)
                
                # 限制章节数量
                if len(chapters) >= self.config["analysis"].get("max_chapters", 50):
                    break
        
        # 如果没有找到章节链接，尝试从内容中提取
        if not chapters:
            chapters = self._extract_chapters_from_content(content)
        
        return chapters
    
    def _is_chapter_link(self, text: str, href: str) -> bool:
        """判断是否是章节链接"""
        # 常见的章节关键词
        chapter_keywords = ['章', '节', '回', '话', '卷', '篇', '集']
        number_patterns = [r'第[零一二三四五六七八九十百千万\d]+章', r'第\d+章']
        
        # 检查是否包含章节关键词
        has_keyword = any(keyword in text for keyword in chapter_keywords)
        
        # 检查是否匹配数字模式
        matches_pattern = any(re.search(pattern, text) for pattern in number_patterns)
        
        # 检查链接是否可能指向章节
        href_lower = href.lower()
        is_chapter_url = any(word in href_lower for word in ['chapter', 'chap', '回', '章'])
        
        return (has_keyword or matches_pattern or is_chapter_url) and len(text) < 50
    
    def _extract_chapters_from_content(self, content: str) -> List[Dict]:
        """从内容中提取章节"""
        chapters = []
        
        # 查找章节标题
        patterns = [
            r'第[零一二三四五六七八九十百千万\d]+章[^\n]{1,50}',
            r'第\d+章[^\n]{1,50}',
            r'[卷篇][零一二三四五六七八九十百千万\d]+[^\n]{1,50}'
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, content)
            for match in matches:
                chapter_title = match.group(0).strip()
                if chapter_title not in [c["title"] for c in chapters]:
                    chapters.append({
                        "title": chapter_title,
                        "url": "",
                        "order": len(chapters) + 1
                    })
        
        return chapters[:self.config["analysis"].get("max_chapters", 50)]
    
    def _analyze_writing_style(self, content: str, chapters: List[Dict]) -> Dict:
        """分析写作风格"""
        # 采样部分内容进行分析
        sample_text = content[:10000]  # 分析前10000字符
        
        style_analysis = {
            "style_type": "未知",
            "dialogue_ratio": 0.0,
            "description_ratio": 0.0,
            "paragraph_length_avg": 0.0,
            "sentence_length_avg": 0.0,
            "common_words": [],
            "special_patterns": []
        }
        
        # 分析对话比例
        dialogue_patterns = ['「', '」', '“', '”', '"', "'", '说道', '问道', '喊道']
        dialogue_count = sum(sample_text.count(pattern) for pattern in dialogue_patterns)
        total_quotes = sample_text.count('「') + sample_text.count('」') + sample_text.count('"') + sample_text.count("'")
        style_analysis["dialogue_ratio"] = dialogue_count / max(len(sample_text), 1)
        
        # 分析段落长度
        paragraphs = [p.strip() for p in sample_text.split('\n') if p.strip()]
        if paragraphs:
            style_analysis["paragraph_length_avg"] = sum(len(p) for p in paragraphs) / len(paragraphs)
        
        # 分析句子长度
        sentences = re.split(r'[。！？!?]', sample_text)
        sentences = [s.strip() for s in sentences if s.strip()]
        if sentences:
            style_analysis["sentence_length_avg"] = sum(len(s) for s in sentences) / len(sentences)
        
        # 判断风格类型
        if style_analysis["dialogue_ratio"] > 0.3:
            style_analysis["style_type"] = "对话驱动型"
        elif style_analysis["paragraph_length_avg"] > 200:
            style_analysis["style_type"] = "描写细腻型"
        elif style_analysis["sentence_length_avg"] < 20:
            style_analysis["style_type"] = "简洁明快型"
        else:
            style_analysis["style_type"] = "平衡型"
        
        return style_analysis
    
    def _extract_characters(self, content: str, chapters: List[Dict]) -> List[Dict]:
        """提取角色"""
        characters = []
        
        # 常见的中文人名模式
        name_patterns = [
            r'[赵钱孙李周吴郑王冯陈褚卫蒋沈韩杨朱秦尤许何吕施张孔曹严华金魏陶姜戚谢邹喻柏水窦章云苏潘葛奚范彭郎鲁韦昌马苗凤花方俞任袁柳酆鲍史唐费廉岑薛雷贺倪汤滕殷罗毕郝邬安常乐于时傅皮卞齐康伍余元卜顾孟平黄和穆萧尹姚邵湛汪祁毛禹狄米贝明臧计伏成戴谈宋茅庞熊纪舒屈项祝董梁杜阮蓝闵席季麻强贾路娄危江童颜郭梅盛林刁钟徐邱骆高夏蔡田樊胡凌霍虞万支柯昝管卢莫经房裘缪干解应宗丁宣贲邓郁单杭洪包诸左石崔吉钮龚程嵇邢滑裴陆荣翁荀羊於惠甄曲家封芮羿储靳汲邴糜松井段富巫乌焦巴弓牧隗山谷车侯宓蓬全郗班仰秋仲伊宫宁仇栾暴甘钭厉戎祖武符刘景詹束龙叶幸司韶郜黎蓟薄印宿白怀蒲邰从鄂索咸籍赖卓蔺屠蒙池乔阴鬱胥能苍双闻莘党翟谭贡劳逄姬申扶堵冉宰郦雍卻璩桑桂濮牛寿通边扈燕冀郏浦尚农温别庄晏柴瞿阎充慕连茹习宦艾鱼容向古易慎戈廖庾终暨居衡步都耿满弘匡国文寇广禄阙东欧殳沃利蔚越夔隆师巩厍聂晁勾敖融冷訾辛阚那简饶空曾毋沙乜养鞠须丰巢关蒯相查后荆红游竺权逯盖益桓公][\u4e00-\u9fa5]{1,2}'
        ]
        
        # 从内容中提取人名
        all_names = set()
        for pattern in name_patterns:
            matches = re.findall(pattern, content[:50000])  # 只分析前50000字符
            all_names.update(matches)
        
        # 统计出现频率
        name_freq = {}
        for name in all_names:
            if 2 <= len(name) <= 4:  # 合理的人名长度
                freq = content.count(name)
                if freq >= 3:  # 至少出现3次才认为是重要角色
                    name_freq[name] = freq
        
        # 按频率排序
        sorted_names = sorted(name_freq.items(), key=lambda x: x[1], reverse=True)
        
        # 创建角色信息
        for name, freq in sorted_names[:10]:  # 只取前10个
            character = {
                "name": name,
                "frequency": freq,
                "role": self._guess_character_role(name, content),
                "gender": self._guess_character_gender(name)
            }
            characters.append(character)
        
        return characters
    
    def _guess_character_role(self, name: str, content: str) -> str:
        """猜测角色身份"""
        # 在名字周围提取上下文
        context_pattern = f'.{{0,50}}{name}.{{0,50}}'
        contexts = re.findall(context_pattern, content[:20000])
        
        role_keywords = {
            "主角": ["主角", "主人公", "主要人物", "英雄", "侠客", "少年", "少女"],
            "反派": ["反派", "恶人", "敌人", "对手", "魔王", "妖怪", "恶霸"],
            "导师": ["师父", "师傅", "老师", "导师", "前辈", "长老", "仙人"],
            "伙伴": ["朋友", "伙伴", "兄弟", "姐妹", "同伴", "队友", "同盟"],
            "恋人": ["爱人", "恋人", "情侣", "夫妻", "娘子", "相公", "心上人"],
            "配角": ["配角", "次要人物", "路人", "群众", "村民", "士兵", "仆人"]
        }
        
        for role, keywords in role_keywords.items():
            for context in contexts:
                if any(keyword in context for keyword in keywords):
                    return role
        
        return "未知"
    
    def _guess_character_gender(self, name: str) -> str:
        """猜测角色性别"""
        # 常见的女性名字用字
        female_chars = ['娟', '婷', '娜', '莉', '芳', '玲', '秀', '英', '慧', '淑', 
                       '雅', '静', '美', '艳', '娇', '妹', '娘', '娥', '媛', '妮']
        
        # 常见的男性名字用字
        male_chars = ['伟', '强', '勇', '军', '杰', '斌', '涛', '明', '亮', '健',
                     '雄', '峰', '刚', '鹏', '飞', '龙', '虎', '彪', '威', '豪']
        
        for char in name:
            if char in female_chars:
                return "女"
            elif char in male_chars:
                return "男"
        
        return "未知"
    
    def _analyze_plot_structure(self, chapters: List[Dict]) -> Dict:
        """分析情节结构"""
        # 基于章节标题分析
        chapter_titles = [chapter["title"] for chapter in chapters]
        
        structure = {
            "total_chapters": len(chapters),
            "estimated_arcs": max(1, len(chapters) // 20),  # 每20章一个故事弧
            "chapter_groups": [],
            "key_points": []
        }
        
        # 识别关键章节
        key_chapter_keywords = ['开端', '发展', '高潮', '结局', '转折', '危机', '决战', '重逢']
        for i, title in enumerate(chapter_titles):
            for keyword in key_chapter_keywords:
                if keyword in title:
                    structure["key_points"].append({
                        "chapter": i + 1,
                        "title": title,
                        "type": keyword
                    })
                    break
        
        return structure
    
    def _calculate_avg_length(self, chapters: List[Dict]) -> float:
        """计算平均章节长度（估算）"""
        if not chapters:
            return 0.0
        
        # 基于章节数量估算
        avg_words_per_chapter = 2000  # 假设每章2000字
        return avg_words_per_chapter
    
    def _detect_content_type
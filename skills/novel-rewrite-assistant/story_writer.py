#!/usr/bin/env python3
"""
故事创作模块
仿照参考小说创作新故事
"""

import random
import re
from typing import Dict, List
from datetime import datetime


class StoryWriter:
    """故事创作器"""
    
    def __init__(self, config: Dict):
        self.config = config
        
        # 场景模板
        self.scene_templates = {
            "玄幻": ["宗门", "山洞", "森林", "城镇", "秘境", "战场", "宫殿", "山谷"],
            "都市": ["公司", "咖啡厅", "公园", "家里", "餐厅", "街道", "商场", "学校"],
            "言情": ["校园", "海边", "餐厅", "家里", "公园", "电影院", "商场", "旅行地"],
            "科幻": ["太空站", "实验室", "飞船", "未来城市", "外星基地", "虚拟世界", "战场"]
        }
        
        # 情节模板
        self.plot_templates = [
            "遇到困难，努力克服",
            "发现秘密，揭开真相", 
            "遭遇背叛，重新振作",
            "获得奇遇，实力提升",
            "面对选择，做出决定",
            "遭遇危机，化险为夷",
            "结识新友，共同成长",
            "挑战强敌，证明自己",
            "经历考验，获得认可",
            "陷入困境，寻找出路"
        ]
        
        # 对话模板
        self.dialogue_templates = [
            "「{char1}，你终于来了。」{char2}说道。",
            "{char1}看着{char2}，问道：「你为什么要这样做？」",
            "「不用担心，」{char2}安慰道，「一切都会好起来的。」",
            "{char1}摇了摇头：「不，这件事没有这么简单。」",
            "「相信我，」{char2}坚定地说，「我们一定能成功。」",
            "{char1}叹了口气：「也许你是对的。」",
            "「小心！」{char2}突然喊道。",
            "{char1}微微一笑：「我早就料到了。」"
        ]
        
        # 描写模板
        self.description_templates = [
            "阳光透过{scene}的窗户洒进来，照亮了整个房间。",
            "{scene}里弥漫着一种神秘的气氛。",
            "站在{scene}中央，{char}感受到一股强大的力量。",
            "{scene}的景色美得令人窒息。",
            "在{scene}中，时间仿佛静止了。",
            "{scene}里充满了各种奇怪的声音。",
            "走进{scene}，{char}立刻被眼前的景象震撼了。",
            "{scene}的空气中飘散着淡淡的花香。"
        ]
    
    def generate_outline(self, 
                        analysis_result: Dict,
                        story_framework: Dict,
                        protagonist: Dict,
                        supporting_chars: List[Dict]) -> Dict:
        """生成故事大纲"""
        genre = story_framework.get("genre", "玄幻")
        main_plot = story_framework.get("main_plot", "少年成长故事")
        
        # 分析参考小说的结构
        original_structure = analysis_result.get("plot_structure", {})
        estimated_chapters = original_structure.get("total_chapters", 20)
        
        # 生成章节结构
        chapter_count = min(
            max(self.config["writing"]["min_chapters"], 
                min(estimated_chapters, self.config["writing"]["max_chapters"])),
            100
        )
        
        # 生成主要情节点
        plot_points = self._generate_plot_points(main_plot, chapter_count, genre)
        
        # 生成章节标题
        chapter_titles = self._generate_chapter_titles(chapter_count, genre)
        
        # 构建大纲
        outline = {
            "title": story_framework.get("title", "新创作的小说"),
            "genre": genre,
            "main_plot": main_plot,
            "ending": story_framework.get("ending", "圆满结局"),
            "total_chapters": chapter_count,
            "main_plot_points": plot_points,
            "chapter_titles": chapter_titles,
            "key_characters": {
                "protagonist": protagonist["name"],
                "supporting": [char["name"] for char in supporting_chars[:5]]
            },
            "theme": story_framework.get("theme", "成长与冒险")
        }
        
        return outline
    
    def _generate_plot_points(self, main_plot: str, chapter_count: int, genre: str) -> List[str]:
        """生成主要情节点"""
        plot_points = []
        
        # 开篇
        plot_points.append(f"开篇：介绍主角和背景，{main_plot}的开始")
        
        # 发展
        mid_point = chapter_count // 2
        plot_points.append(f"第{mid_point//3}章左右：第一次重大事件，主角开始成长")
        plot_points.append(f"第{mid_point}章：故事转折点，主角面临重大选择")
        
        # 高潮
        climax_point = chapter_count * 3 // 4
        plot_points.append(f"第{climax_point}章：故事高潮，主角面对最大挑战")
        
        # 结局
        plot_points.append(f"第{chapter_count}章：结局，{main_plot}的收尾")
        
        # 添加随机情节点
        additional_points = random.sample(self.plot_templates, min(3, len(self.plot_templates)))
        for point in additional_points:
            chapter = random.randint(2, chapter_count - 1)
            plot_points.append(f"第{chapter}章左右：{point}")
        
        return plot_points
    
    def _generate_chapter_titles(self, chapter_count: int, genre: str) -> List[str]:
        """生成章节标题"""
        titles = []
        
        # 根据题材选择标题风格
        if genre in ["玄幻", "仙侠", "武侠"]:
            title_words = ["入门", "试炼", "突破", "奇遇", "挑战", "决战", 
                          "传承", "秘境", "宗门", "长老", "师兄", "师姐"]
        elif genre in ["都市", "现代"]:
            title_words = ["初遇", "合作", "竞争", "危机", "转机", "成功",
                          "选择", "挑战", "机遇", "成长", "突破", "成就"]
        elif genre in ["言情", "爱情"]:
            title_words = ["相遇", "相识", "相知", "相爱", "误会", "和解",
                          "考验", "承诺", "离别", "重逢", "永恒", "幸福"]
        else:
            title_words = ["开始", "发展", "转折", "高潮", "结局", "新生"]
        
        for i in range(1, chapter_count + 1):
            if i == 1:
                titles.append("开篇")
            elif i == chapter_count:
                titles.append("终章")
            else:
                # 随机组合标题
                word1 = random.choice(title_words)
                word2 = random.choice(title_words)
                if random.random() > 0.5:
                    title = f"{word1}{word2}"
                else:
                    title = word1
                titles.append(title)
        
        return titles
    
    def write_chapters(self,
                      outline: Dict,
                      analysis_result: Dict,
                      protagonist: Dict,
                      supporting_chars: List[Dict]) -> List[Dict]:
        """创作章节内容"""
        chapters = []
        chapter_count = outline["total_chapters"]
        genre = outline["genre"]
        
        # 获取写作风格参考
        writing_style = analysis_result.get("writing_style", {})
        style_type = writing_style.get("style_type", "平衡型")
        
        print(f"开始创作{chapter_count}章内容，风格：{style_type}")
        
        for i in range(1, chapter_count + 1):
            chapter_title = outline["chapter_titles"][i-1] if i-1 < len(outline["chapter_titles"]) else f"第{i}章"
            
            print(f"  创作第{i}章: {chapter_title}")
            
            # 生成章节内容
            content = self._write_chapter_content(
                chapter_num=i,
                total_chapters=chapter_count,
                protagonist=protagonist,
                supporting_chars=supporting_chars,
                genre=genre,
                style_type=style_type,
                outline=outline
            )
            
            chapter = {
                "number": i,
                "title": chapter_title,
                "content": content,
                "word_count": len(content),
                "key_events": self._extract_key_events(content)
            }
            
            chapters.append(chapter)
        
        return chapters
    
    def _write_chapter_content(self,
                              chapter_num: int,
                              total_chapters: int,
                              protagonist: Dict,
                              supporting_chars: List[Dict],
                              genre: str,
                              style_type: str,
                              outline: Dict) -> str:
        """创作单章内容"""
        content_parts = []
        
        # 1. 场景描写
        scene = self._generate_scene(genre, chapter_num)
        scene_desc = random.choice(self.description_templates)
        scene_desc = scene_desc.replace("{scene}", scene).replace("{char}", protagonist["name"])
        content_parts.append(scene_desc)
        
        # 2. 主角出场
        protagonist_desc = self._describe_character(protagonist, "出场")
        content_parts.append(protagonist_desc)
        
        # 3. 根据章节位置决定内容
        if chapter_num == 1:
            # 开篇章节
            content_parts.append(f"这是{protagonist['name']}的故事开始的地方。")
            content_parts.append(f"{protagonist['name']}{protagonist.get('background', '')}。")
            
            # 引入第一个配角
            if supporting_chars:
                first_char = supporting_chars[0]
                char_desc = self._describe_character(first_char, "引入")
                content_parts.append(char_desc)
                
                # 添加对话
                dialogue = self._generate_dialogue(protagonist["name"], first_char["name"])
                content_parts.append(dialogue)
        
        elif chapter_num == total_chapters:
            # 结局章节
            content_parts.append(f"经过漫长的旅程，{protagonist['name']}终于来到了故事的终点。")
            content_parts.append(f"{outline.get('ending', '故事圆满结束')}。")
            
            # 与主要配角互动
            main_chars = [c for c in supporting_chars if c["type"] in ["朋友", "恋人", "伙伴"]]
            if main_chars:
                for char in main_chars[:2]:
                    content_parts.append(f"{char['name']}走到{protagonist['name']}身边。")
                    dialogue = self._generate_dialogue(protagonist["name"], char["name"], "结局")
                    content_parts.append(dialogue)
        
        else:
            # 中间章节
            # 选择本章的配角
            available_chars = [c for c in supporting_chars if c["type"] not in ["反派", "对手"] or chapter_num % 3 == 0]
            if available_chars:
                chapter_char = random.choice(available_chars)
                
                # 描述相遇
                content_parts.append(f"在{scene}，{protagonist['name']}遇到了{chapter_char['name']}。")
                
                # 添加对话
                dialogue = self._generate_dialogue(protagonist["name"], chapter_char["name"])
                content_parts.append(dialogue)
                
                # 添加情节
                plot_template = random.choice(self.plot_templates)
                content_parts.append(f"就在这时，{plot_template}。")
            
            # 添加一些描写
            extra_desc = random.choice(self.description_templates)
            extra_desc = extra_desc.replace("{scene}", scene).replace("{char}", protagonist["name"])
            content_parts.append(extra_desc)
        
        # 4. 章节结尾
        if chapter_num < total_chapters:
            # 悬念结尾
            cliffhangers = [
                f"然而，{protagonist['name']}并不知道，更大的挑战正在前方等待着他。",
                f"{protagonist['name']}深吸一口气，准备迎接接下来的考验。",
                f"就在这时，远处传来了奇怪的声音...",
                f"{protagonist['name']}心中涌起一股不祥的预感。"
            ]
            content_parts.append(random.choice(cliffhangers))
        else:
            # 故事结尾
            endings = [
                f"故事到这里就结束了，但{protagonist['name']}的传奇仍在继续。",
                f"{protagonist['name']}望着远方，心中充满了希望。",
                f"这是一个结束，也是一个新的开始。",
                f"传奇落幕，但记忆永存。"
            ]
            content_parts.append(random.choice(endings))
        
        # 组合内容
        content = "\n\n".join(content_parts)
        
        # 根据风格调整内容长度
        target_length = self.config["writing"].get("chapter_length", 3000)
        current_length = len(content)
        
        if current_length < target_length * 0.7:
            # 内容太短，添加更多描写
            extra_content = self._add_extra_content(protagonist, scene, genre)
            content += "\n\n" + extra_content
        
        return content
    
    def _generate_scene(self, genre: str, chapter_num: int) -> str:
        """生成场景"""
        if genre in self.scene_templates:
            scenes = self.scene_templates[genre]
        else:
            scenes = self.scene_templates["玄幻"]
        
        scene = random.choice(scenes)
        
        # 根据章节添加修饰
        modifiers = ["古老的", "神秘的", "繁华的", "寂静的", "危险的", "美丽的"]
        if chapter_num % 4 == 0:
            scene = f"{random.choice(modifiers)}{scene}"
        
        return scene
    
    def _describe_character(self, character: Dict, context: str) -> str:
        """描述角色"""
        name = character["name"]
        
        if context == "出场":
            templates = [
                f"{name}站在那儿，{character.get('appearance', '身影挺拔')}。",
                f"这就是{name}，{character.get('personality', '性格独特')}的{character.get('age', '年轻人')}。",
                f"{name}出现了，{character.get('background', '来历神秘')}。"
            ]
        elif context == "引入":
            templates = [
                f"这时，{name}走了过来。",
                f"不远处，{name}正朝这边看来。",
                f"{name}的出现让气氛发生了变化。"
            ]
        else:
            templates = [f"{name}就在那里。"]
        
        return random.choice(templates)
    
    def _generate_dialogue(self, char1: str, char2: str, context: str = "普通") -> str:
        """生成对话"""
        template = random.choice(self.dialogue_templates)
        
        # 随机决定谁先说
        if random.random() > 0.5:
            dialogue = template.replace("{char1}", char1).replace("{char2}", char2)
        else:
            # 交换角色
            dialogue = template.replace("{char1}", char2).replace("{char2}", char1)
        
        # 根据上下文调整
        if context == "结局":
            # 更正式、深刻的对话
            dialogue = dialogue.replace("说道", "郑重地说道").replace("问道", "轻声问道")
        
        return dialogue
    
    def _add_extra_content(self, protagonist: Dict, scene: str, genre: str) -> str:
        """添加额外内容"""
        extra_parts = []
        
        # 添加环境描写
        env_descriptions = [
            f"{scene}的空气中弥漫着特殊的气息。",
            f"阳光（或月光）洒在{scene}的每一个角落。",
            f"{scene}里的一切都显得那么宁静（或喧嚣）。",
            f"站在{scene}中，{protagonist['name']}能感受到时间的流逝。"
        ]
        extra_parts.append(random.choice(env_descriptions))
        
        # 添加心理描写
        thoughts = [
            f"{protagonist['name']}心中思绪万千。",
            f"回忆起过往的经历，{protagonist['name']}不禁感慨。",
            f"{protagonist['name']}思考着接下来的计划。",
            f"一股复杂的情绪在{protagonist['name']}心中涌动。"
        ]
        extra_parts.append(random.choice(thoughts))
        
        # 添加动作描写
        actions = [
            f"{protagonist['name']}轻轻叹了口气。",
            f"{protagonist['name']}握紧了拳头。",
            f"{protagonist['name']}抬头望向远方。",
            f"{protagonist['name']}微微一笑。"
        ]
        extra_parts.append(random.choice(actions))
        
        return "\n\n".join(extra_parts)
    
    def _extract_key_events(self, content: str) -> List[str]:
        """提取关键事件"""
        # 简单提取：找到包含特定关键词的句子
        event_keywords = ["遇到", "发现", "遭遇", "获得", "面对", "挑战", "经历", "陷入"]
        sentences = re.split(r'[。！？!?]', content)
        
        events = []
        for sentence in sentences:
            if any(keyword in sentence for keyword in event_keywords):
                events.append(sentence.strip())
        
        return events[:3]  # 最多返回3个关键事件


# 测试代码
if __name__ == "__main__":
    config = {
        "writing": {
            "min_chapters": 10,
            "max_chapters": 20,
            "chapter_length": 2000
        }
    }
    
    writer = StoryWriter(config)
    
    # 测试大纲生成
    outline = writer.generate_outline(
        analysis_result={"plot_structure": {"total_chapters": 30}},
        story_framework={"genre": "玄幻", "main_plot": "少年修仙", "title": "修仙传奇"},
        protagonist={"name": "林风"},
        supporting_chars=[]
    )
    
    print("生成的故事大纲:")
    print(f"标题: {outline['title']}")
    print(f"题材: {outline['genre']}")
    print(f"章节数
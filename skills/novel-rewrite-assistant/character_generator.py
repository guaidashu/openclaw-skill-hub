#!/usr/bin/env python3
"""
角色生成模块
自动生成配角名字和角色关系
"""

import json
import random
from pathlib import Path
from typing import Dict, List, Optional
import re


class CharacterGenerator:
    """角色生成器"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.name_db_path = Path(config["generation"].get("name_database", "name_database"))
        self.name_db = self._load_name_database()
        
        # 常见姓氏
        self.common_surnames = [
            '赵', '钱', '孙', '李', '周', '吴', '郑', '王', '冯', '陈',
            '褚', '卫', '蒋', '沈', '韩', '杨', '朱', '秦', '尤', '许',
            '何', '吕', '施', '张', '孔', '曹', '严', '华', '金', '魏',
            '陶', '姜', '戚', '谢', '邹', '喻', '柏', '水', '窦', '章',
            '云', '苏', '潘', '葛', '奚', '范', '彭', '郎', '鲁', '韦'
        ]
        
        # 男性名字常用字
        self.male_chars = [
            '伟', '强', '勇', '军', '杰', '斌', '涛', '明', '亮', '健',
            '雄', '峰', '刚', '鹏', '飞', '龙', '虎', '彪', '威', '豪',
            '文', '武', '斌', '博', '超', '晨', '成', '诚', '达', '德',
            '东', '方', '风', '光', '海', '浩', '华', '辉', '建', '江',
            '杰', '俊', '凯', '磊', '林', '明', '宁', '平', '强', '荣',
            '瑞', '森', '涛', '伟', '文', '武', '祥', '鑫', '阳', '毅',
            '宇', '渊', '云', '泽', '振', '志', '智', '忠', '洲', '卓'
        ]
        
        # 女性名字常用字
        self.female_chars = [
            '娟', '婷', '娜', '莉', '芳', '玲', '秀', '英', '慧', '淑',
            '雅', '静', '美', '艳', '娇', '妹', '娘', '娥', '媛', '妮',
            '洁', '梅', '兰', '竹', '菊', '萍', '红', '彤', '颖', '悦',
            '敏', '倩', '茜', '珊', '莎', '蓉', '薇', '雯', '霞', '雪',
            '燕', '怡', '莹', '玉', '玥', '云', '芸', '珍', '珠', '姿',
            '爱', '宝', '彩', '婵', '丹', '芬', '凤', '桂', '荷', '花',
            '慧', '佳', '娇', '洁', '静', '娟', '兰', '丽', '琳', '玲',
            '梅', '美', '娜', '妮', '萍', '倩', '琴', '清', '蓉', '珊',
            '淑', '婷', '雯', '霞', '香', '秀', '雪', '艳', '燕', '瑶'
        ]
        
        # 特殊背景名字（仙侠、武侠等）
        self.fantasy_chars = [
            '玄', '冥', '幽', '幻', '影', '魂', '魄', '灵', '仙', '神',
            '魔', '妖', '鬼', '怪', '龙', '凤', '麒', '麟', '青', '白',
            '紫', '金', '银', '墨', '夜', '星', '月', '日', '辰', '曦',
            '风', '云', '雷', '电', '雨', '雪', '霜', '雾', '露', '虹'
        ]
    
    def _load_name_database(self) -> Dict:
        """加载名字数据库"""
        db_file = self.name_db_path / "names.json"
        if db_file.exists():
            try:
                with open(db_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                pass
        
        # 返回空数据库
        return {
            "surnames": self.common_surnames,
            "male_names": self.male_chars,
            "female_names": self.female_chars,
            "fantasy_names": self.fantasy_chars,
            "generated_names": []
        }
    
    def generate_supporting_characters(self, 
                                     analysis_result: Dict,
                                     protagonist: Dict,
                                     story_framework: Dict) -> List[Dict]:
        """生成配角"""
        max_chars = self.config["generation"].get("max_supporting_chars", 10)
        genre = story_framework.get("genre", "玄幻")
        
        # 确定需要生成的配角类型
        character_types = self._determine_character_types(genre, analysis_result)
        
        # 生成配角
        supporting_chars = []
        used_names = {protagonist["name"]}
        
        for char_type in character_types[:max_chars]:
            # 生成名字
            name = self._generate_name(char_type, genre, used_names)
            used_names.add(name)
            
            # 生成角色信息
            character = {
                "name": name,
                "type": char_type,
                "gender": self._determine_gender(char_type),
                "age": self._generate_age(char_type),
                "personality": self._generate_personality(char_type),
                "background": self._generate_background(char_type, genre),
                "relationship": self._generate_relationship(char_type, protagonist["name"]),
                "role": self._get_role_description(char_type),
                "appearance": self._generate_appearance(char_type, genre)
            }
            
            supporting_chars.append(character)
        
        return supporting_chars
    
    def _determine_character_types(self, genre: str, analysis_result: Dict) -> List[str]:
        """确定需要的配角类型"""
        base_types = [
            "导师", "伙伴", "恋人", "反派", "盟友", "对手",
            "家人", "朋友", "敌人", "中立者"
        ]
        
        # 根据题材调整
        if genre in ["玄幻", "仙侠", "武侠"]:
            types = ["师父", "师兄", "师姐", "师弟", "师妹", 
                    "长老", "掌门", "魔头", "妖王", "仙人"]
        elif genre in ["都市", "现代"]:
            types = ["上司", "同事", "朋友", "恋人", "家人",
                    "对手", "合作伙伴", "导师", "学生"]
        elif genre in ["言情", "爱情"]:
            types = ["恋人", "情敌", "朋友", "家人", "前任",
                    "闺蜜", "兄弟", "长辈", "晚辈"]
        elif genre in ["科幻", "未来"]:
            types = ["科学家", "军官", "队友", "敌人", "AI",
                    "外星人", "指挥官", "技术员"]
        else:
            types = base_types
        
        # 从分析结果中获取角色类型
        original_chars = analysis_result.get("main_characters", [])
        if original_chars:
            # 提取原作的配角类型
            original_types = [char.get("role", "") for char in original_chars]
            types = list(set(types + original_types))
        
        return types[:15]  # 限制类型数量
    
    def _generate_name(self, char_type: str, genre: str, used_names: set) -> str:
        """生成名字"""
        max_attempts = 20
        
        for _ in range(max_attempts):
            # 选择姓氏
            surname = random.choice(self.common_surnames)
            
            # 根据角色类型和题材选择名字风格
            if genre in ["玄幻", "仙侠", "武侠"]:
                # 仙侠风格名字
                if char_type in ["师父", "长老", "掌门", "仙人"]:
                    # 长辈或高人：单字名
                    given = random.choice(self.fantasy_chars)
                    name = f"{surname}{given}"
                else:
                    # 普通角色：双字名
                    given1 = random.choice(self.fantasy_chars)
                    given2 = random.choice(self.male_chars + self.female_chars)
                    name = f"{surname}{given1}{given2}"
            else:
                # 普通风格名字
                gender = self._determine_gender(char_type)
                if gender == "男":
                    given_chars = self.male_chars
                else:
                    given_chars = self.female_chars
                
                # 随机选择1-2个字
                given_length = random.choice([1, 2])
                if given_length == 1:
                    given = random.choice(given_chars)
                    name = f"{surname}{given}"
                else:
                    given1 = random.choice(given_chars)
                    given2 = random.choice(given_chars)
                    name = f"{surname}{given1}{given2}"
            
            # 检查名字是否已使用
            if name not in used_names:
                return name
        
        # 如果所有尝试都失败，生成随机名字
        return f"{random.choice(self.common_surnames)}某"
    
    def _determine_gender(self, char_type: str) -> str:
        """确定角色性别"""
        # 明显男性角色
        male_types = ["师父", "师兄", "师弟", "长老", "掌门", "魔头",
                     "妖王", "上司", "兄弟", "科学家", "军官", "指挥官"]
        
        # 明显女性角色
        female_types = ["师姐", "师妹", "恋人", "情敌", "闺蜜", "前任"]
        
        if char_type in male_types:
            return "男"
        elif char_type in female_types:
            return "女"
        else:
            # 随机选择
            return random.choice(["男", "女"])
    
    def _generate_age(self, char_type: str) -> str:
        """生成年龄"""
        if char_type in ["师父", "长老", "掌门", "仙人", "长辈"]:
            return random.choice(["50多岁", "60多岁", "70多岁", "百岁高龄"])
        elif char_type in ["师兄", "师姐", "同事", "朋友"]:
            return random.choice(["20多岁", "30多岁", "40多岁"])
        elif char_type in ["师弟", "师妹", "学生", "晚辈"]:
            return random.choice(["10多岁", "20岁左右", "20出头"])
        else:
            return random.choice(["20多岁", "30多岁", "40多岁"])
    
    def _generate_personality(self, char_type: str) -> str:
        """生成性格"""
        personalities = {
            "导师": ["严肃认真", "慈祥和蔼", "深藏不露", "严格苛刻", "智慧深邃"],
            "伙伴": ["忠诚可靠", "幽默风趣", "冷静沉着", "热情开朗", "勇敢无畏"],
            "恋人": ["温柔体贴", "坚强独立", "善解人意", "活泼可爱", "成熟稳重"],
            "反派": ["阴险狡诈", "冷酷无情", "野心勃勃", "残忍暴戾", "工于心计"],
            "盟友": ["正直守信", "精明能干", "豪爽大方", "谨慎小心", "果断坚决"],
            "对手": ["骄傲自负", "顽强不屈", "机智过人", "冷酷傲慢", "执着坚定"],
            "家人": ["慈爱关怀", "严格管教", "支持鼓励", "保护过度", "理解包容"],
            "朋友": ["真诚友善", "乐于助人", "风趣幽默", "可靠信任", "共同成长"]
        }
        
        # 查找匹配的性格
        for key, traits in personalities.items():
            if key in char_type:
                return random.choice(traits)
        
        # 默认性格
        default_traits = ["神秘莫测", "性格复杂", "多重性格", "难以捉摸", "普通平凡"]
        return random.choice(default_traits)
    
    def _generate_background(self, char_type: str, genre: str) -> str:
        """生成背景故事"""
        backgrounds = {
            "玄幻": {
                "师父": ["隐世高人", "宗门长老", "散修强者", "转世仙人"],
                "伙伴": ["同门师兄弟", "冒险途中结识", "救命恩人", "志同道合"],
                "反派": ["魔道巨擘", "宗门叛徒", "妖族王者", "邪修高手"]
            },
            "都市": {
                "上司": ["公司高管", "部门主管", "创业伙伴", "行业前辈"],
                "同事": ["同期入职", "项目搭档", "竞争对手", "职场好友"],
                "恋人": ["青梅竹马", "工作相识", "偶然邂逅", "朋友介绍"]
            },
            "言情": {
                "恋人": ["校园初恋", "职场精英", "家族联姻", "意外相遇"],
                "情敌": ["前任恋人", "暗恋对象", "商业对手", "家族世仇"],
                "家人": ["严格父亲", "温柔母亲", "关心兄长", "调皮妹妹"]
            }
        }
        
        # 根据题材和角色类型选择背景
        if genre in backgrounds:
            genre_bg = backgrounds[genre]
            for key, bg_list in genre_bg.items():
                if key in char_type:
                    return random.choice(bg_list)
        
        # 默认背景
        default_bg = [
            "来历神秘", "普通出身", "世家子弟", "寒门学子",
            "江湖游侠", "职场精英", "学院天才", "平凡之人"
        ]
        return random.choice(default_bg)
    
    def _generate_relationship(self, char_type: str, protagonist_name: str) -> str:
        """生成与主角的关系"""
        relationships = {
            "师父": f"{protagonist_name}的授业恩师",
            "师兄": f"{protagonist_name}的师兄，关系密切",
            "师姐": f"{protagonist_name}的师姐，照顾有加",
            "师弟": f"{protagonist_name}的师弟，尊敬师兄",
            "师妹": f"{protagonist_name}的师妹，仰慕师兄",
            "恋人": f"{protagonist_name}的爱人，感情深厚",
            "朋友": f"{protagonist_name}的挚友，生死之交",
            "反派": f"{protagonist_name}的主要对手，势不两立",
            "家人": f"{protagonist_name}的亲人，血浓于水",
            "盟友": f"{protagonist_name}的合作伙伴，利益一致"
        }
        
        # 查找匹配的关系
        for key, relation in relationships.items():
            if key in char_type:
                return relation
        
        # 默认关系
        return f"与{protagonist_name}有复杂关系"
    
    def _get_role_description(self, char_type: str) -> str:
        """获取角色作用描述"""
        roles = {
            "导师": "引导主角成长，传授知识和技能",
            "伙伴": "陪伴主角冒险，共同面对挑战",
            "恋人": "与主角发展感情线，提供情感支持",
            "反派": "制造冲突和障碍，推动剧情发展",
            "盟友": "在关键时刻提供帮助和支持",
            "对手": "与主角竞争，促使主角进步",
            "家人": "提供家庭背景和情感纽带",
            "朋友": "日常互动，丰富主角生活"
        }
        
        for key, role in roles.items():
            if key in char_type:
                return role
        
        return "推动剧情发展的重要角色"
    
    def _generate_appearance(self, char_type: str, genre: str) -> str:
        """生成外貌描述"""
        if genre in ["玄幻", "仙侠", "武侠"]:
            appearances = {
                "师父": ["仙风道骨", "白发苍苍", "目光如电", "气质超凡"],
                "师兄": ["英俊潇洒", "气宇轩昂", "剑眉星目", "风度翩翩"],
                "师姐": ["清丽脱俗", "貌美如花", "气质冷艳", "温婉动人"],
                "反派": ["面目狰狞", "眼神阴冷", "气势逼人", "邪气凛然"]
            }
        elif genre in ["都市", "现代"]:
            appearances = {
                "上司": ["西装革履", "精明干练", "气场强大", "严肃认真"],
                "同事": ["普通打扮", "亲切随和", "专业形象", "时尚潮流"],
                "恋人": ["阳光帅气", "美丽动人", "气质独特", "引人注目"]
            }
        else:
            appearances = {}
        
        # 查找匹配的外貌
        for key, appear_list in appearances.items():
            if key in char_type:
                return random.choice(appear_list)
        
        # 默认外貌
        default_appear = [
            "相貌普通", "长相清秀", "外貌出众", "气质独特",
            "身材匀称", "眼神明亮", "笑容亲切", "姿态优雅"
        ]
        return random.choice(default_appear)
    
    def build_relationships(self, 
                          protagonist: Dict,
                          supporting_chars: List[Dict],
                          analysis_result: Dict) -> Dict:
        """构建角色关系网络"""
        relationships = {
            "protagonist": protagonist["name"],
            "character_network": [],
            "relationship_map": {}
        }
        
        # 构建主角与其他角色的关系
        for char in supporting_chars:
            relation = {
                "from": protagonist["name"],
                "to": char["name"],
                "type": char["relationship"],
                "strength": random.choice(["强", "中", "弱"]),
                "nature": random.choice(["正面", "负面", "复杂"])
            }

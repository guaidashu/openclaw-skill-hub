#!/usr/bin/env python3
"""
简化版角色生成器
"""

import random
from typing import Dict, List


class SimpleCharacterGenerator:
    """简化角色生成器"""
    
    def __init__(self):
        # 常见姓氏
        self.surnames = ['李', '王', '张', '刘', '陈', '杨', '赵', '黄', '周', '吴',
                        '徐', '孙', '胡', '朱', '高', '林', '何', '郭', '马', '罗']
        
        # 男性名字
        self.male_names = ['伟', '强', '勇', '军', '杰', '斌', '涛', '明', '亮', '健',
                          '雄', '峰', '刚', '鹏', '飞', '龙', '虎', '彪', '威', '豪']
        
        # 女性名字
        self.female_names = ['娟', '婷', '娜', '莉', '芳', '玲', '秀', '英', '慧', '淑',
                            '雅', '静', '美', '艳', '娇', '妹', '娘', '娥', '媛', '妮']
        
        # 仙侠风格
        self.fantasy_names = ['玄', '冥', '幽', '幻', '影', '魂', '灵', '仙', '神', '魔']
    
    def generate_name(self, gender="random", style="normal") -> str:
        """生成名字"""
        surname = random.choice(self.surnames)
        
        if gender == "random":
            gender = random.choice(["male", "female"])
        
        if style == "fantasy":
            # 仙侠风格
            given = random.choice(self.fantasy_names)
            return f"{surname}{given}"
        else:
            # 普通风格
            if gender == "male":
                given = random.choice(self.male_names)
            else:
                given = random.choice(self.female_names)
            
            # 50%概率加第二个字
            if random.random() > 0.5:
                given2 = random.choice(self.male_names + self.female_names)
                return f"{surname}{given}{given2}"
            else:
                return f"{surname}{given}"
    
    def generate_supporting_chars(self, protagonist_name: str, genre: str, count: int = 5) -> List[Dict]:
        """生成配角"""
        char_types = self._get_char_types(genre)
        chars = []
        used_names = {protagonist_name}
        
        for i in range(min(count, len(char_types))):
            char_type = char_types[i]
            
            # 生成唯一名字
            while True:
                if genre in ["玄幻", "仙侠", "武侠"]:
                    name = self.generate_name(style="fantasy")
                else:
                    gender = self._get_gender_for_type(char_type)
                    name = self.generate_name(gender)
                
                if name not in used_names:
                    used_names.add(name)
                    break
            
            # 创建角色
            char = {
                "name": name,
                "type": char_type,
                "gender": self._get_gender_for_type(char_type),
                "personality": self._get_personality(char_type),
                "relationship": self._get_relationship(char_type, protagonist_name),
                "role": self._get_role(char_type)
            }
            
            chars.append(char)
        
        return chars
    
    def _get_char_types(self, genre: str) -> List[str]:
        """获取角色类型"""
        if genre in ["玄幻", "仙侠", "武侠"]:
            return ["师父", "师兄", "师姐", "反派", "伙伴", "恋人", "长老", "对手"]
        elif genre in ["都市", "现代"]:
            return ["上司", "同事", "朋友", "恋人", "家人", "对手", "导师", "伙伴"]
        elif genre in ["言情", "爱情"]:
            return ["恋人", "情敌", "朋友", "家人", "闺蜜", "兄弟", "前任", "同事"]
        else:
            return ["朋友", "家人", "导师", "对手", "伙伴", "盟友", "反派", "中立者"]
    
    def _get_gender_for_type(self, char_type: str) -> str:
        """根据角色类型确定性别"""
        male_types = ["师父", "师兄", "反派", "长老", "上司", "兄弟", "对手"]
        female_types = ["师姐", "恋人", "闺蜜", "情敌", "前任"]
        
        if char_type in male_types:
            return "男"
        elif char_type in female_types:
            return "女"
        else:
            return random.choice(["男", "女"])
    
    def _get_personality(self, char_type: str) -> str:
        """获取性格"""
        personalities = {
            "师父": ["严肃", "慈祥", "严格", "智慧"],
            "师兄": ["可靠", "幽默", "冷静", "热情"],
            "师姐": ["温柔", "坚强", "体贴", "可爱"],
            "反派": ["阴险", "冷酷", "残忍", "狡猾"],
            "朋友": ["真诚", "友善", "风趣", "可靠"],
            "恋人": ["温柔", "体贴", "善解人意", "活泼"],
            "对手": ["骄傲", "顽强", "机智", "执着"]
        }
        
        for key, traits in personalities.items():
            if key in char_type:
                return random.choice(traits)
        
        return random.choice(["神秘", "复杂", "普通", "独特"])
    
    def _get_relationship(self, char_type: str, protagonist: str) -> str:
        """获取关系描述"""
        relationships = {
            "师父": f"{protagonist}的师父",
            "师兄": f"{protagonist}的师兄",
            "师姐": f"{protagonist}的师姐", 
            "朋友": f"{protagonist}的朋友",
            "恋人": f"{protagonist}的恋人",
            "反派": f"{protagonist}的对手",
            "对手": f"{protagonist}的竞争者",
            "家人": f"{protagonist}的家人"
        }
        
        for key, relation in relationships.items():
            if key in char_type:
                return relation
        
        return f"与{protagonist}相识"
    
    def _get_role(self, char_type: str) -> str:
        """获取角色作用"""
        roles = {
            "师父": "引导主角成长",
            "朋友": "陪伴主角冒险", 
            "恋人": "发展感情线",
            "反派": "制造冲突",
            "对手": "促使主角进步",
            "家人": "提供情感支持"
        }
        
        for key, role in roles.items():
            if key in char_type:
                return role
        
        return "推动剧情发展"


# 测试代码
if __name__ == "__main__":
    gen = SimpleCharacterGenerator()
    
    # 测试名字生成
    print("测试名字生成:")
    for _ in range(5):
        print(f"  普通名: {gen.generate_name()}")
        print(f"  仙侠名: {gen.generate_name(style='fantasy')}")
    
    # 测试配角生成
    print("\n测试配角生成（玄幻题材）:")
    chars = gen.generate_supporting_chars("林风", "玄幻", 3)
    for char in chars:
        print(f"  名字: {char['name']}, 类型: {char['type']}, 性格: {char['personality']}")
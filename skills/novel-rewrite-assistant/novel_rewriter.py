#!/usr/bin/env python3
"""
小说仿写助手 - 主程序
分析参考小说并仿照创作新故事
"""

import sys
import os
import json
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from analyzer import NovelAnalyzer
from character_generator import CharacterGenerator
from story_writer import StoryWriter


class NovelRewriter:
    """小说仿写助手主类"""
    
    def __init__(self, config_path: str = "config.json"):
        """初始化"""
        self.config = self.load_config(config_path)
        self.analyzer = NovelAnalyzer(self.config)
        self.character_gen = CharacterGenerator(self.config)
        self.writer = StoryWriter(self.config)
        
        # 工作目录
        self.workspace = Path("workspace")
        self.workspace.mkdir(exist_ok=True)
        
    def load_config(self, config_path: str) -> Dict:
        """加载配置文件"""
        default_config = {
            "analysis": {
                "max_chapters": 50,
                "min_chapter_length": 500,
                "extract_dialogues": True,
                "detect_plot_points": True,
                "timeout": 30
            },
            "generation": {
                "name_style": "chinese",
                "auto_relationships": True,
                "character_depth": "medium",
                "max_supporting_chars": 10,
                "name_database": "name_database"
            },
            "writing": {
                "style_imitation": True,
                "scene_variation": True,
                "plot_adaptation": True,
                "chapter_length": 3000,
                "output_format": "markdown",
                "min_chapters": 10,
                "max_chapters": 100
            },
            "cache": {
                "enabled": True,
                "ttl": 86400,
                "max_size": 1000000,
                "cache_dir": "cache"
            }
        }
        
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    # 合并配置
                    self.deep_update(default_config, user_config)
            except Exception as e:
                print(f"警告: 配置文件加载失败，使用默认配置: {e}")
        
        return default_config
    
    def deep_update(self, base: Dict, update: Dict) -> Dict:
        """深度更新字典"""
        for key, value in update.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self.deep_update(base[key], value)
            else:
                base[key] = value
        return base
    
    def analyze_novel(self, url: str, analyze_only: bool = False) -> Dict:
        """分析参考小说"""
        print(f"开始分析小说: {url}")
        
        # 分析小说
        analysis_result = self.analyzer.analyze(url)
        
        if not analysis_result:
            print("错误: 小说分析失败")
            return None
        
        print(f"分析完成:")
        print(f"  标题: {analysis_result.get('title', '未知')}")
        print(f"  作者: {analysis_result.get('author', '未知')}")
        print(f"  章节数: {len(analysis_result.get('chapters', []))}")
        print(f"  主要角色: {len(analysis_result.get('main_characters', []))}")
        print(f"  写作风格: {analysis_result.get('writing_style', {}).get('style_type', '未知')}")
        
        # 保存分析结果
        analysis_file = self.workspace / "analysis_result.json"
        with open(analysis_file, 'w', encoding='utf-8') as f:
            json.dump(analysis_result, f, ensure_ascii=False, indent=2)
        
        print(f"分析结果已保存到: {analysis_file}")
        
        if analyze_only:
            return analysis_result
        
        return analysis_result
    
    def create_new_story(self, analysis_result: Dict, 
                        protagonist: Dict,
                        story_framework: Dict) -> Dict:
        """创建新故事"""
        print("开始创作新故事...")
        
        # 1. 生成配角
        print("生成配角...")
        supporting_chars = self.character_gen.generate_supporting_characters(
            analysis_result, protagonist, story_framework
        )
        
        # 2. 构建角色关系
        print("构建角色关系...")
        character_relationships = self.character_gen.build_relationships(
            protagonist, supporting_chars, analysis_result
        )
        
        # 3. 生成故事大纲
        print("生成故事大纲...")
        story_outline = self.writer.generate_outline(
            analysis_result, story_framework, protagonist, supporting_chars
        )
        
        # 4. 创作章节内容
        print("创作章节内容...")
        chapters = self.writer.write_chapters(
            story_outline, analysis_result, protagonist, supporting_chars
        )
        
        # 5. 组装完整故事
        print("组装完整故事...")
        new_story = {
            "title": story_framework.get("title", "新创作的小说"),
            "author": protagonist.get("author", "AI创作助手"),
            "protagonist": protagonist,
            "supporting_characters": supporting_chars,
            "character_relationships": character_relationships,
            "story_outline": story_outline,
            "chapters": chapters,
            "metadata": {
                "original_novel": analysis_result.get("title"),
                "created_at": analysis_result.get("analysis_time"),
                "style_imitated": analysis_result.get("writing_style", {}).get("style_type")
            }
        }
        
        return new_story
    
    def save_story(self, story: Dict, output_format: str = "markdown") -> str:
        """保存故事到文件"""
        output_file = self.workspace / f"{story['title']}.{output_format}"
        
        if output_format == "json":
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(story, f, ensure_ascii=False, indent=2)
        elif output_format == "markdown":
            self._save_as_markdown(story, output_file)
        elif output_format == "txt":
            self._save_as_text(story, output_file)
        else:
            print(f"警告: 不支持的格式 {output_format}，使用markdown")
            self._save_as_markdown(story, output_file)
        
        print(f"故事已保存到: {output_file}")
        return str(output_file)
    
    def _save_as_markdown(self, story: Dict, output_file: Path):
        """保存为Markdown格式"""
        with open(output_file, 'w', encoding='utf-8') as f:
            # 标题
            f.write(f"# {story['title']}\n\n")
            
            # 作者信息
            f.write(f"**作者**: {story['author']}\n\n")
            f.write(f"**创作时间**: {story['metadata']['created_at']}\n\n")
            f.write(f"**参考作品**: {story['metadata']['original_novel']}\n\n")
            f.write(f"**仿照风格**: {story['metadata']['style_imitated']}\n\n")
            
            # 主角信息
            f.write("## 主角\n\n")
            protagonist = story['protagonist']
            f.write(f"**姓名**: {protagonist['name']}\n\n")
            f.write(f"**年龄**: {protagonist.get('age', '未知')}\n\n")
            f.write(f"**性格**: {protagonist.get('personality', '未知')}\n\n")
            f.write(f"**背景**: {protagonist.get('background', '未知')}\n\n")
            
            # 配角信息
            if story['supporting_characters']:
                f.write("## 主要配角\n\n")
                for char in story['supporting_characters'][:10]:  # 只显示前10个
                    f.write(f"### {char['name']}\n\n")
                    f.write(f"- **关系**: {char.get('relationship', '未知')}\n")
                    f.write(f"- **性格**: {char.get('personality', '未知')}\n")
                    f.write(f"- **作用**: {char.get('role', '未知')}\n\n")
            
            # 故事大纲
            f.write("## 故事大纲\n\n")
            outline = story['story_outline']
            for i, point in enumerate(outline.get('main_plot_points', []), 1):
                f.write(f"{i}. {point}\n")
            f.write("\n")
            
            # 章节内容
            f.write("## 正文\n\n")
            for i, chapter in enumerate(story['chapters'], 1):
                f.write(f"### 第{i}章 {chapter.get('title', f'第{i}章')}\n\n")
                f.write(f"{chapter.get('content', '')}\n\n")
    
    def _save_as_text(self, story: Dict, output_file: Path):
        """保存为纯文本格式"""
        with open(output_file, 'w', encoding='utf-8') as f:
            # 标题
            f.write(f"{story['title']}\n")
            f.write("=" * 50 + "\n\n")
            
            # 章节内容
            for i, chapter in enumerate(story['chapters'], 1):
                f.write(f"第{i}章 {chapter.get('title', f'第{i}章')}\n")
                f.write("-" * 50 + "\n\n")
                f.write(f"{chapter.get('content', '')}\n\n")
    
    def interactive_mode(self):
        """交互式模式"""
        print("欢迎使用小说仿写助手！")
        print("=" * 50)
        
        # 1. 输入参考小说URL
        url = input("请输入参考小说URL: ").strip()
        if not url:
            print("错误: URL不能为空")
            return
        
        # 2. 分析小说
        analysis_result = self.analyze_novel(url, analyze_only=False)
        if not analysis_result:
            return
        
        # 3. 输入主角信息
        print("\n请定义主角信息:")
        protagonist = {
            "name": input("主角姓名: ").strip() or "林风",
            "age": input("年龄: ").strip() or "18岁",
            "personality": input("性格特点: ").strip() or "聪明但内向",
            "background": input("背景故事: ").strip() or "普通高中生",
            "author": input("作者名（可选）: ").strip() or "AI创作助手"
        }
        
        # 4. 定义剧情框架
        print("\n请定义剧情框架:")
        story_framework = {
            "title": input("小说标题: ").strip() or "新创作的小说",
            "genre": input("题材类型（如：玄幻、都市、言情）: ").strip() or "玄幻",
            "main_plot": input("主线剧情: ").strip() or "少年成长，逆袭成为强者",
            "ending": input("结局设想: ").strip() or "成为顶尖强者，守护重要之人",
            "theme": input("主题思想（可选）: ").strip() or "成长与守护"
        }
        
        # 5. 创作参数
        print("\n创作参数设置:")
        try:
            chapter_count = int(input("章节数量（默认10）: ").strip() or "10")
            chapter_count = max(5, min(100, chapter_count))  # 限制范围
        except ValueError:
            chapter_count = 10
        
        self.config["writing"]["min_chapters"] = chapter_count
        self.config["writing"]["max_chapters"] = chapter_count
        
        # 6. 开始创作
        print(f"\n开始创作《{story_framework['title']}》...")
        new_story = self.create_new_story(analysis_result, protagonist, story_framework)
        
        # 7. 保存结果
        output_format = input("输出格式（markdown/txt/json，默认markdown）: ").strip().lower() or "markdown"
        output_file = self.save_story(new_story, output_format)
        
        print(f"\n✅ 创作完成！")
        print(f"📖 作品: 《{new_story['title']}》")
        print(f"👤 主角: {protagonist['name']}")
        print(f"📄 章节: {len(new_story['chapters'])}章")
        print(f"💾 文件: {output_file}")
        print(f"🎨 风格: 仿照《{analysis_result.get('title', '参考小说')}》")


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="小说仿写助手")
    parser.add_argument("url", nargs="?", help="参考小说URL")
    parser.add_argument("--protagonist", help="主角信息JSON文件或字符串")
    parser.add_argument("--framework", help="剧情框架JSON文件或字符串")
    parser.add_argument("--output", "-o", default="novel.md", help="输出文件")
    parser.add_argument("--format", "-f", default="markdown", 
                       choices=["markdown", "txt", "json"], help="输出格式")
    parser.add_argument("--chapters", "-c", type=int, default=10, help="章节数量")
    parser.add_argument("--analyze-only", "-a", action="store_true", 
                       help="只分析不创作")
    parser.add_argument("--interactive", "-i", action="store_true", 
                       help="交互式模式")
    parser.add_argument("--config", default="config.json", help="配置文件")
    
    args = parser.parse_args()
    
    # 创建重写器
    rewriter = NovelRewriter(args.config)
    
    if args.interactive:
        # 交互式模式
        rewriter.interactive_mode()
    elif args.url:
        # 命令行模式
        if args.analyze_only:
            # 只分析
            analysis_result = rewriter.analyze_novel(args.url, analyze_only=True)
        else:
            # 完整创作流程
            # 加载主角信息和剧情框架
            protagonist = {}
            story_framework = {}
            
            if args.protagonist:
                if os.path.exists(args.protagonist):
                    with open(args.protagonist, 'r', encoding='utf-8') as f:
                        protagonist = json.load(f)
                else:
                    try:
                        protagonist = json.loads(args.protagonist)
                    except:
                        protagonist = {"name": args.protagonist}
            
            if args.framework:
                if os.path.exists(args.framework):
                    with open(args.framework, 'r', encoding='utf-8') as f:
                        story_framework = json.load(f)
                else:
                    try:
                        story_framework = json.loads(args.framework)
                    except:
                        story_framework = {"title": args.framework}
            
            # 设置章节数
            rewriter.config["writing"]["min_chapters"] = args.chapters
            rewriter.config["writing"]["max_chapters"] = args.chapters
            
            # 分析小说
            analysis_result = rewriter.analyze_novel(args.url, analyze_only=False)
            
            if analysis_result:
                # 创作新故事
                new_story = rewriter.create_new_story(
                    analysis_result, protagonist, story_framework
                )
                
                # 保存故事
                rewriter.save_story(new_story, args.format)
    else:
        # 显示帮助
        parser.print_help()
        print("\n示例:")
        print("  交互式模式: python novel_rewriter.py -i")
        print("  分析小说: python novel_rewriter.py https://example.com/novel -a")
        print("  完整创作: python novel_rewriter.py https://example.com/novel \\")
        print("            --protagonist '{\"name\":\"林风\"}' \\")
        print("            --framework '{\"title\":\"新小说\"}'")


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
简化版小说仿写助手
"""

import sys
import os
import json
import argparse
from pathlib import Path
from datetime import datetime

# 导入模块
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from analyzer_complete import NovelAnalyzer
    from simple_character_gen import SimpleCharacterGenerator
    from story_writer import StoryWriter
except ImportError as e:
    print(f"导入模块失败: {e}")
    print("请确保所有依赖文件都存在")
    sys.exit(1)


class SimpleNovelRewriter:
    """简化版小说仿写器"""
    
    def __init__(self):
        # 基础配置
        self.config = {
            "analysis": {"max_chapters": 20},
            "generation": {"max_supporting_chars": 8},
            "writing": {"min_chapters": 10, "max_chapters": 30, "chapter_length": 1500},
            "cache": {"enabled": True, "ttl": 3600, "cache_dir": "cache"}
        }
        
        self.analyzer = NovelAnalyzer(self.config)
        self.char_gen = SimpleCharacterGenerator()
        self.writer = StoryWriter(self.config)
        
        # 创建工作目录
        self.workspace = Path("novel_output")
        self.workspace.mkdir(exist_ok=True)
    
    def run_interactive(self):
        """交互式运行"""
        print("=" * 60)
        print("小说仿写助手 - 简化版")
        print("=" * 60)
        
        # 1. 输入参考小说URL
        print("\n📚 第一步：输入参考小说")
        print("-" * 40)
        url = input("请输入参考小说的URL: ").strip()
        if not url:
            print("❌ URL不能为空")
            return
        
        # 2. 分析小说
        print("\n🔍 正在分析参考小说...")
        analysis = self.analyzer.analyze(url)
        if not analysis:
            print("❌ 小说分析失败，请检查URL或网络连接")
            return
        
        print(f"✅ 分析完成:")
        print(f"   标题: {analysis.get('title', '未知')}")
        print(f"   作者: {analysis.get('author', '未知')}")
        print(f"   章节: {len(analysis.get('chapters', []))}章")
        
        # 3. 输入主角信息
        print("\n👤 第二步：定义主角")
        print("-" * 40)
        protagonist = {
            "name": input("主角姓名（默认：林风）: ").strip() or "林风",
            "age": input("年龄（默认：18岁）: ").strip() or "18岁",
            "personality": input("性格（默认：聪明勇敢）: ").strip() or "聪明勇敢",
            "background": input("背景（默认：普通少年）: ").strip() or "普通少年"
        }
        
        # 4. 选择题材和框架
        print("\n📖 第三步：选择故事框架")
        print("-" * 40)
        print("可选题材: 玄幻, 都市, 言情, 科幻, 武侠, 仙侠")
        genre = input("题材类型（默认：玄幻）: ").strip() or "玄幻"
        
        print("\n请输入故事主线（例如：少年获得奇遇，踏上修仙之路）")
        main_plot = input("故事主线: ").strip() or "少年获得奇遇，踏上成长之路"
        
        story_framework = {
            "title": input("小说标题（默认：新创作的小说）: ").strip() or "新创作的小说",
            "genre": genre,
            "main_plot": main_plot,
            "ending": input("结局设想（默认：成为强者，守护重要之人）: ").strip() or "成为强者，守护重要之人"
        }
        
        # 5. 设置章节数
        print("\n📄 第四步：设置章节")
        print("-" * 40)
        try:
            chapters = int(input("章节数量（10-50，默认：20）: ").strip() or "20")
            chapters = max(10, min(50, chapters))
        except:
            chapters = 20
        
        self.config["writing"]["min_chapters"] = chapters
        self.config["writing"]["max_chapters"] = chapters
        
        # 6. 开始创作
        print("\n✨ 开始创作新小说...")
        print("-" * 40)
        
        # 生成配角
        print("生成配角...")
        supporting_chars = self.char_gen.generate_supporting_chars(
            protagonist["name"], genre, count=6
        )
        
        # 生成大纲
        print("生成故事大纲...")
        outline = self.writer.generate_outline(
            analysis, story_framework, protagonist, supporting_chars
        )
        
        # 创作章节
        print(f"创作{chapters}章内容...")
        all_chapters = self.writer.write_chapters(
            outline, analysis, protagonist, supporting_chars
        )
        
        # 7. 保存结果
        print("\n💾 保存创作结果...")
        self._save_results(story_framework, protagonist, supporting_chars, outline, all_chapters)
        
        print("\n🎉 创作完成！")
        print("=" * 60)
    
    def _save_results(self, framework, protagonist, supporting_chars, outline, chapters):
        """保存结果"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        base_name = f"{framework['title']}_{timestamp}"
        
        # 1. 保存完整JSON
        json_data = {
            "metadata": {
                "created_at": datetime.now().isoformat(),
                "original_novel": "参考小说分析结果",
                "style": "仿写创作"
            },
            "framework": framework,
            "protagonist": protagonist,
            "supporting_characters": supporting_chars,
            "outline": outline,
            "chapters": chapters
        }
        
        json_file = self.workspace / f"{base_name}.json"
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=2)
        
        # 2. 保存为Markdown（可读格式）
        md_file = self.workspace / f"{base_name}.md"
        self._save_as_markdown(md_file, framework, protagonist, supporting_chars, outline, chapters)
        
        # 3. 保存为纯文本（小说正文）
        txt_file = self.workspace / f"{base_name}.txt"
        self._save_as_text(txt_file, framework, chapters)
        
        print(f"✅ 结果已保存:")
        print(f"   JSON数据: {json_file}")
        print(f"   Markdown: {md_file}")
        print(f"   纯文本: {txt_file}")
    
    def _save_as_markdown(self, filepath, framework, protagonist, supporting_chars, outline, chapters):
        """保存为Markdown格式"""
        with open(filepath, 'w', encoding='utf-8') as f:
            # 标题
            f.write(f"# {framework['title']}\n\n")
            
            # 基本信息
            f.write("## 基本信息\n\n")
            f.write(f"- **题材**: {framework['genre']}\n")
            f.write(f"- **主线**: {framework['main_plot']}\n")
            f.write(f"- **结局**: {framework['ending']}\n")
            f.write(f"- **创作时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # 主角信息
            f.write("## 主角\n\n")
            f.write(f"**姓名**: {protagonist['name']}\n\n")
            f.write(f"**年龄**: {protagonist['age']}\n\n")
            f.write(f"**性格**: {protagonist['personality']}\n\n")
            f.write(f"**背景**: {protagonist['background']}\n\n")
            
            # 配角信息
            if supporting_chars:
                f.write("## 主要配角\n\n")
                for char in supporting_chars:
                    f.write(f"### {char['name']}\n\n")
                    f.write(f"- **类型**: {char['type']}\n")
                    f.write(f"- **性别**: {char['gender']}\n")
                    f.write(f"- **性格**: {char['personality']}\n")
                    f.write(f"- **关系**: {char['relationship']}\n")
                    f.write(f"- **作用**: {char['role']}\n\n")
            
            # 故事大纲
            f.write("## 故事大纲\n\n")
            for i, point in enumerate(outline.get('main_plot_points', []), 1):
                f.write(f"{i}. {point}\n")
            f.write("\n")
            
            # 章节内容
            f.write("## 正文\n\n")
            for chapter in chapters:
                f.write(f"### 第{chapter['number']}章 {chapter['title']}\n\n")
                f.write(f"{chapter['content']}\n\n")
    
    def _save_as_text(self, filepath, framework, chapters):
        """保存为纯文本格式"""
        with open(filepath, 'w', encoding='utf-8') as f:
            # 标题
            f.write(f"{framework['title']}\n")
            f.write("=" * 50 + "\n\n")
            
            # 章节内容
            for chapter in chapters:
                f.write(f"第{chapter['number']}章 {chapter['title']}\n")
                f.write("-" * 50 + "\n\n")
                f.write(f"{chapter['content']}\n\n")


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="简化版小说仿写助手")
    parser.add_argument("-i", "--interactive", action="store_true", help="交互式模式")
    parser.add_argument("--url", help="参考小说URL")
    parser.add_argument("--name", default="林风", help="主角姓名")
    parser.add_argument("--genre", default="玄幻", help="题材类型")
    parser.add_argument("--title", default="新创作的小说", help="小说标题")
    parser.add_argument("--chapters", type=int, default=20, help="章节数量")
    parser.add_argument("--output", default="novel_output", help="输出目录")
    
    args = parser.parse_args()
    
    # 创建重写器
    rewriter = SimpleNovelRewriter()
    
    if args.interactive or not args.url:
        # 交互式模式
        rewriter.run_interactive()
    else:
        # 命令行模式
        print("命令行模式暂未实现完整功能，请使用交互式模式 (-i)")
        print("示例: python novel_rewrite_simple.py -i")


if __name__ == "__main__":
    main()
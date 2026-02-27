#!/bin/bash

# 技能打包脚本
# 将技能目录打包成标准格式，准备提交到Skill Hub

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# 显示帮助
show_help() {
    echo "用法: package.sh [选项] <技能目录> [技能ID]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -o, --output     指定输出目录（默认: ./packages）"
    echo "  -f, --force      强制覆盖已存在的包"
    echo "  -v, --validate   打包前先验证技能格式"
    echo "  --no-clean       不清理临时文件（用于调试）"
    echo ""
    echo "示例:"
    echo "  package.sh ~/skills/weather"
    echo "  package.sh -o ./dist ~/skills/my-skill my-skill-id"
    echo "  package.sh -v ~/skills/weather"
}

# 验证技能目录
validate_skill() {
    local skill_dir="$1"
    
    info "验证技能格式..."
    
    if ! "$SCRIPT_DIR/validate.sh" "$skill_dir" > /dev/null 2>&1; then
        error "技能验证失败，请先修复错误"
        echo ""
        echo "运行以下命令查看详细错误:"
        echo "  $SCRIPT_DIR/validate.sh -v \"$skill_dir\""
        return 1
    fi
    
    success "技能验证通过"
    return 0
}

# 提取技能信息
extract_skill_info() {
    local skill_dir="$1"
    local skill_md="$skill_dir/SKILL.md"
    
    local skill_info="{}"
    
    if [ -f "$skill_md" ]; then
        # 提取技能名称
        local skill_name
        skill_name=$(grep -m1 "^# SKILL.md - " "$skill_md" | sed 's/^# SKILL.md - //' | sed 's/^ *//;s/ *$//')
        if [ -n "$skill_name" ]; then
            skill_info=$(echo "$skill_info" | jq --arg name "$skill_name" '. + {name: $name}' 2>/dev/null || echo "$skill_info")
        fi
        
        # 提取触发词
        local triggers_line
        triggers_line=$(grep -A1 "**触发词**" "$skill_md" | tail -1 | sed 's/^*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$triggers_line" ]; then
            # 将逗号分隔的触发词转换为数组
            local triggers_array=()
            IFS=',' read -ra triggers <<< "$triggers_line"
            for trigger in "${triggers[@]}"; do
                triggers_array+=("$(echo "$trigger" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')")
            done
            # 构建JSON数组（简化版，不使用jq）
            local triggers_json="["
            for ((i=0; i<${#triggers_array[@]}; i++)); do
                triggers_json+="\"${triggers_array[i]}\""
                if [ $i -lt $((${#triggers_array[@]} - 1)) ]; then
                    triggers_json+=","
                fi
            done
            triggers_json+="]"
            # 这里简化处理，实际应该使用jq
        fi
        
        # 提取描述
        local description
        description=$(grep -A1 "**描述**" "$skill_md" | tail -1 | sed 's/^*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$description" ]; then
            skill_info=$(echo "$skill_info" | jq --arg desc "$description" '. + {description: $desc}' 2>/dev/null || echo "$skill_info")
        fi
        
        # 提取作者
        local author
        author=$(grep -A1 "**作者**" "$skill_md" | tail -1 | sed 's/^*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$author" ]; then
            skill_info=$(echo "$skill_info" | jq --arg auth "$author" '. + {author: $auth}' 2>/dev/null || echo "$skill_info")
        fi
        
        # 提取版本
        local version
        version=$(grep -A1 "**版本**" "$skill_md" | tail -1 | sed 's/^*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$version" ]; then
            skill_info=$(echo "$skill_info" | jq --arg ver "$version" '. + {version: $ver}' 2>/dev/null || echo "$skill_info")
        fi
    fi
    
    echo "$skill_info"
}

# 创建技能包
create_package() {
    local skill_dir="$1"
    local skill_id="$2"
    local output_dir="$3"
    local force="$4"
    
    # 获取技能目录名作为默认ID
    if [ -z "$skill_id" ]; then
        skill_id=$(basename "$skill_dir")
        info "使用目录名作为技能ID: $skill_id"
    fi
    
    # 检查技能ID格式
    if ! echo "$skill_id" | grep -qE '^[a-z0-9-]+$'; then
        error "技能ID格式错误: 只能包含小写字母、数字和连字符"
        error "当前ID: $skill_id"
        error "有效示例: weather, coding-agent, my-skill-123"
        return 1
    fi
    
    # 创建输出目录
    local package_dir="$output_dir/$skill_id"
    if [ -d "$package_dir" ]; then
        if [ "$force" = "true" ]; then
            warning "覆盖已存在的包: $package_dir"
            rm -rf "$package_dir"
        else
            error "包已存在: $package_dir"
            error "使用 -f 选项强制覆盖"
            return 1
        fi
    fi
    
    mkdir -p "$package_dir"
    
    # 复制技能文件
    info "复制技能文件..."
    cp -r "$skill_dir"/* "$package_dir/" 2>/dev/null || true
    
    # 确保必需文件存在
    if [ ! -f "$package_dir/SKILL.md" ]; then
        error "复制后缺少 SKILL.md 文件"
        return 1
    fi
    
    # 创建package.json
    info "创建 package.json..."
    local skill_info
    skill_info=$(extract_skill_info "$skill_dir")
    
    local package_json="{
  \"skill\": {
    \"id\": \"$skill_id\",
    \"name\": \"$(echo "$skill_info" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "$skill_id")\",
    \"description\": \"$(echo "$skill_info" | grep -o '"description":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "No description")\",
    \"author\": \"$(echo "$skill_info" | grep -o '"author":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "unknown")\",
    \"version\": \"$(echo "$skill_info" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "1.0.0")\",
    \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
    \"files\": []
  }
}"
    
    echo "$package_json" > "$package_dir/package.json"
    
    # 添加文件列表
    find "$package_dir" -type f -name "*.md" -o -name "*.sh" -o -name "*.json" | sed "s|$package_dir/||" | while read -r file; do
        local file_type="other"
        case "$file" in
            *.md) file_type="markdown" ;;
            *.sh) file_type="script" ;;
            *.json) file_type="json" ;;
        esac
        
        # 更新package.json（简化版）
        if [ "$file" != "package.json" ]; then
            echo "  - $file ($file_type)" >> "$package_dir/file-list.txt"
        fi
    done
    
    # 设置文件权限
    info "设置文件权限..."
    find "$package_dir" -name "*.sh" -type f -exec chmod +x {} \;
    chmod -R 755 "$package_dir"
    
    # 计算包大小
    local package_size
    package_size=$(du -sh "$package_dir" | cut -f1)
    
    success "技能包创建成功！"
    echo ""
    echo "包信息:"
    echo "  - 技能ID: $skill_id"
    echo "  - 包目录: $package_dir"
    echo "  - 包大小: $package_size"
    echo "  - 文件数: $(find "$package_dir" -type f | wc -l)"
    echo ""
    echo "包内容:"
    find "$package_dir" -type f | sed "s|$package_dir/|  - |" | sort
    
    return 0
}

# 生成提交指南
generate_submission_guide() {
    local package_dir="$1"
    local skill_id="$2"
    local output_dir="$3"
    
    local guide_file="$output_dir/SUBMISSION_GUIDE.md"
    
    info "生成提交指南..."
    
    cat > "$guide_file" << EOF
# 技能提交指南

技能: $(basename "$package_dir")
生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 提交到 OpenClaw Skill Hub

### 方法一：通过GitHub网页提交（推荐）

1. **访问仓库**: https://github.com/guaidashu/openclaw-skill-hub
2. **Fork仓库**: 点击右上角 "Fork" 按钮
3. **克隆你的Fork**:
   \`\`\`bash
   git clone https://github.com/你的用户名/openclaw-skill-hub.git
   cd openclaw-skill-hub
   \`\`\`

4. **添加技能文件**:
   \`\`\`bash
   # 复制技能包到skills目录
   cp -r "$package_dir" skills/
   \`\`\`

5. **更新注册表**:
   编辑 \`registry.json\` 文件，添加你的技能信息:
   \`\`\`json
   {
     "id": "$skill_id",
     "name": "技能名称",
     "description": "技能描述",
     "author": "你的名字",
     "version": "1.0.0",
     "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
     "triggers": ["关键词1", "关键词2"],
     "dependencies": [],
     "path": "skills/$skill_id"
   }
   \`\`\`

6. **提交更改**:
   \`\`\`bash
   git add .
   git commit -m "添加技能: $skill_id"
   git push origin main
   \`\`\`

7. **创建Pull Request**:
   - 访问你的Fork仓库页面
   - 点击 "Pull requests" → "New pull request"
   - 选择 base: guaidashu/openclaw-skill-hub (main)
   - 选择 compare: 你的用户名/openclaw-skill-hub (main)
   - 填写PR标题和描述
   - 点击 "Create pull request"

### 方法二：使用GitHub CLI（如果已安装）

\`\`\`bash
# 克隆仓库
gh repo clone guaidashu/openclaw-skill-hub
cd openclaw-skill-hub

# 创建新分支
git checkout -b add-skill-$skill_id

# 添加技能文件
cp -r "$package_dir" skills/

# 更新注册表（手动编辑registry.json）

# 提交更改
git add .
git commit -m "添加技能: $skill_id"

# 推送并创建PR
git push origin add-skill-$skill_id
gh pr create --title "添加技能: $skill_id" --body "请审核我的技能提交"
\`\`\`

### 方法三：使用技能提交工具（如果可用）

\`\`\`bash
# 安装提交工具后
skill-hub-submit "$package_dir"
\`\`\`

## 审核流程

1. **格式检查**: 确保技能符合标准格式
2. **功能测试**: 验证技能功能正常
3. **安全审查**: 检查无恶意代码
4. **合并发布**: 审核通过后合并到主分支

## 注意事项

1. **技能ID**: 必须唯一，使用小写字母、数字和连字符
2. **文件大小**: 单个技能不超过10MB
3. **依赖声明**: 明确声明所有依赖
4. **文档完整**: 提供完整的SKILL.md和README.md
5. **测试通过**: 确保技能在提交前经过测试

## 联系支持

如有问题，请:
1. 在GitHub仓库创建Issue
2. 或联系Skill Hub管理员

祝提交顺利！

EOF
    
    success "提交指南已生成: $guide_file"
}

# 主函数
main() {
    local skill_dir=""
    local skill_id=""
    local output_dir="./packages"
    local force="false"
    local validate="false"
    local no_clean="false"
    
    # 获取脚本目录
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -v|--validate)
                validate="true"
                shift
                ;;
            --no-clean)
                no_clean="true"
                shift
                ;;
            -*)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$skill_dir" ]; then
                    skill_dir="$1"
                elif [ -z "$skill_id" ]; then
                    skill_id="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 检查参数
    if [ -z "$skill_dir" ]; then
        error "请指定技能目录"
        show_help
        exit 1
    fi
    
    # 检查目录是否存在
    if [ ! -d "$skill_dir" ]; then
        error "技能目录不存在: $skill_dir"
        exit 1
    fi
    
    # 获取绝对路径
    skill_dir=$(cd "$skill_dir" && pwd)
    output_dir=$(mkdir -p "$output_dir" && cd "$output_dir" && pwd)
    
    log "开始打包技能..."
    log "技能目录: $skill_dir"
    log "输出目录: $output_dir"
    log "技能ID: ${skill_id:-自动生成}"
    
    # 验证技能（如果启用）
    if [ "$validate" = "true" ]; then
        if ! validate_skill "$skill_dir"; then
            exit 1
        fi
    fi
    
    # 创建技能包
    if ! create_package "$skill_dir" "$skill_id" "$output_dir" "$force"; then
        exit 1
    fi
    
    local package_dir="$output_dir/$skill_id"
    if [ -z "$skill_id" ]; then
        package_dir="$output_dir/$(basename "$skill_dir")"
    fi
    
    # 生成提交指南
    generate_submission_guide "$package_dir" "$skill_id" "$output_dir"
    
    # 清理临时文件（如果启用）
    if [ "$no_clean" = "false" ]; then
        info "清理临时文件..."
        find "$output_dir" -name "*.tmp" -o -name "*.temp" -delete 2>/dev/null || true
    fi
    
    echo ""
    success "打包完成！"
    echo ""
    echo "下一步操作:"
    echo "1. 查看技能包: ls -la \"$package_dir\""
    echo "2. 查看提交指南: cat \"$output_dir/SUBMISSION_GUIDE.md\""
    echo "3. 按照指南提交到Skill Hub"
    echo ""
    echo "快速提交命令（如果已配置GitHub CLI）:"
    echo "  gh pr create --title \"添加技能: $skill_id\" --body \"新技能提交\""
    
    return 0
}

# 异常处理
trap 'error "打包过程中断"; exit 1' INT TERM

# 运行主函数
main "$@"
#!/bin/bash

# 技能提交脚本
# 将技能包提交到OpenClaw Skill Hub

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
    echo "用法: submit.sh [选项] <技能包目录>"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -m, --manual     只生成手动提交指南（不自动提交）"
    echo "  -f, --force      强制提交（跳过部分检查）"
    echo "  --github-token   指定GitHub Personal Access Token"
    echo "  --dry-run        试运行，不实际提交"
    echo ""
    echo "示例:"
    echo "  submit.sh ./packages/weather"
    echo "  submit.sh -m ./packages/my-skill"
    echo "  submit.sh --github-token \$GITHUB_TOKEN ./packages/weather"
}

# 检查GitHub CLI
check_github_cli() {
    if command -v gh &> /dev/null; then
        success "GitHub CLI 已安装"
        return 0
    else
        warning "GitHub CLI 未安装，将使用手动提交模式"
        return 1
    fi
}

# 检查GitHub Token
check_github_token() {
    local token="$1"
    
    if [ -n "$token" ]; then
        # 测试Token有效性
        if curl -s -H "Authorization: token $token" https://api.github.com/user | grep -q '"login"'; then
            success "GitHub Token 有效"
            return 0
        else
            error "GitHub Token 无效"
            return 1
        fi
    fi
    
    # 检查环境变量
    if [ -n "$GITHUB_TOKEN" ]; then
        info "使用环境变量 GITHUB_TOKEN"
        if curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep -q '"login"'; then
            success "环境变量 GitHub Token 有效"
            return 0
        else
            error "环境变量 GitHub Token 无效"
            return 1
        fi
    fi
    
    # 检查gh auth状态
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            success "GitHub CLI 已认证"
            return 0
        fi
    fi
    
    warning "未找到有效的GitHub认证"
    return 1
}

# 验证技能包
validate_package() {
    local package_dir="$1"
    local force="$2"
    
    info "验证技能包..."
    
    # 检查目录是否存在
    if [ ! -d "$package_dir" ]; then
        error "技能包目录不存在: $package_dir"
        return 1
    fi
    
    # 检查必需文件
    local required_files=("SKILL.md" "package.json")
    for file in "${required_files[@]}"; do
        if [ ! -f "$package_dir/$file" ]; then
            error "技能包缺少必需文件: $file"
            if [ "$force" != "true" ]; then
                return 1
            else
                warning "强制模式：跳过 $file 检查"
            fi
        else
            success "找到 $file"
        fi
    done
    
    # 检查技能ID
    local skill_id
    skill_id=$(basename "$package_dir")
    
    # 检查ID格式
    if ! echo "$skill_id" | grep -qE '^[a-z0-9-]+$'; then
        error "技能ID格式错误: $skill_id"
        error "只能包含小写字母、数字和连字符"
        if [ "$force" != "true" ]; then
            return 1
        else
            warning "强制模式：使用当前ID"
        fi
    fi
    
    # 检查文件大小
    local package_size_mb
    package_size_mb=$(du -sm "$package_dir" | cut -f1)
    if [ "$package_size_mb" -gt 10 ]; then
        warning "技能包较大: ${package_size_mb}MB（建议不超过10MB）"
        if [ "$force" != "true" ] && [ "$package_size_mb" -gt 50 ]; then
            error "技能包过大: ${package_size_mb}MB > 50MB"
            return 1
        fi
    else
        success "技能包大小合适: ${package_size_mb}MB"
    fi
    
    success "技能包验证通过"
    return 0
}

# 生成手动提交指南
generate_manual_guide() {
    local package_dir="$1"
    local skill_id="$2"
    
    local guide_file="$package_dir/SUBMISSION_GUIDE.md"
    
    info "生成手动提交指南..."
    
    cat > "$guide_file" << EOF
# 技能提交指南 - $skill_id

## 技能信息
- **技能ID**: $skill_id
- **生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **包目录**: $package_dir

## 提交步骤

### 1. 准备仓库
\`\`\`bash
# 克隆Skill Hub仓库
git clone https://github.com/guaidashu/openclaw-skill-hub.git
cd openclaw-skill-hub

# 创建新分支
git checkout -b add-skill-$skill_id
\`\`\`

### 2. 添加技能文件
\`\`\`bash
# 复制技能包到skills目录
cp -r "$package_dir" skills/
\`\`\`

### 3. 更新注册表
编辑 \`registry.json\` 文件，在skills数组中添加：

\`\`\`json
{
  "id": "$skill_id",
  "name": "$(grep -o '"name":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "$skill_id")",
  "description": "$(grep -o '"description":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "No description")",
  "author": "$(grep -o '"author":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "unknown")",
  "version": "$(grep -o '"version":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "1.0.0")",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "triggers": ["关键词1", "关键词2"],
  "dependencies": [],
  "path": "skills/$skill_id",
  "downloads": 0,
  "rating": 0.0
}
\`\`\`

**注意**: 请根据实际技能修改 triggers 字段。

### 4. 提交更改
\`\`\`bash
git add .
git commit -m "添加技能: $skill_id"
git push origin add-skill-$skill_id
\`\`\`

### 5. 创建Pull Request
1. 访问 https://github.com/guaidashu/openclaw-skill-hub
2. 点击 "Pull requests" → "New pull request"
3. 选择:
   - base repository: guaidashu/openclaw-skill-hub
   - base: main
   - head repository: 你的用户名/openclaw-skill-hub
   - compare: add-skill-$skill_id
4. 填写PR信息:
   - Title: 添加技能: $skill_id
   - Description: 简要描述技能功能和使用方法
5. 点击 "Create pull request"

### 6. 等待审核
- 管理员会审核你的技能
- 可能需要根据反馈进行修改
- 审核通过后技能将被合并

## 技能文件列表
\`\`\`
$(find "$package_dir" -type f | sed "s|$package_dir/||" | sort | sed 's/^/  /')
\`\`\`

## 注意事项
1. 确保技能符合格式标准
2. 提供完整的文档
3. 测试技能功能正常
4. 不要包含敏感信息
5. 遵守开源协议

## 帮助支持
如有问题，请在GitHub仓库创建Issue:
https://github.com/guaidashu/openclaw-skill-hub/issues

祝提交顺利！
EOF
    
    success "提交指南已生成: $guide_file"
    echo ""
    echo "请按照指南中的步骤手动提交技能。"
}

# 自动提交到GitHub
auto_submit_to_github() {
    local package_dir="$1"
    local skill_id="$2"
    local github_token="$3"
    local dry_run="$4"
    
    info "准备自动提交到GitHub..."
    
    # 检查是否在Git仓库中
    if [ ! -d ".git" ]; then
        error "当前不在Git仓库中"
        info "请先克隆仓库: git clone https://github.com/guaidashu/openclaw-skill-hub.git"
        return 1
    fi
    
    # 检查远程仓库
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ ! "$remote_url" =~ openclaw-skill-hub ]]; then
        warning "当前仓库可能不是 openclaw-skill-hub"
        info "远程仓库: $remote_url"
        if [ "$dry_run" != "true" ]; then
            read -p "是否继续？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    fi
    
    # 创建新分支
    local branch_name="add-skill-$skill_id"
    info "创建分支: $branch_name"
    
    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] git checkout -b $branch_name"
    else
        git checkout -b "$branch_name" 2>/dev/null || {
            error "创建分支失败，可能已存在"
            info "尝试切换到现有分支"
            git checkout "$branch_name" 2>/dev/null || return 1
        }
    fi
    
    # 复制技能文件
    local target_dir="skills/$skill_id"
    info "复制技能文件到: $target_dir"
    
    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] mkdir -p $target_dir"
        echo "[DRY RUN] cp -r $package_dir/* $target_dir/"
    else
        mkdir -p "$target_dir"
        cp -r "$package_dir"/* "$target_dir"/
        
        # 移除提交指南（如果存在）
        rm -f "$target_dir/SUBMISSION_GUIDE.md" 2>/dev/null || true
    fi
    
    # 更新注册表（简化版，实际应该使用jq）
    info "更新注册表..."
    
    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] 更新 registry.json（需要手动编辑）"
    else
        # 这里简化处理，实际应该使用jq来更新JSON
        warning "自动更新注册表功能需要jq支持"
        info "请手动编辑 registry.json 文件"
        echo ""
        echo "需要在 registry.json 的 skills 数组中添加:"
        cat << EOF
{
  "id": "$skill_id",
  "name": "$(grep -o '"name":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "$skill_id")",
  "description": "$(grep -o '"description":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "No description")",
  "author": "$(grep -o '"author":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "unknown")",
  "version": "$(grep -o '"version":"[^"]*"' "$package_dir/package.json" | cut -d'"' -f4 2>/dev/null || echo "1.0.0")",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "triggers": ["请填写触发词"],
  "dependencies": [],
  "path": "skills/$skill_id",
  "downloads": 0,
  "rating": 0.0
}
EOF
        echo ""
        read -p "按回车继续（需要手动编辑registry.json）..." -r
    fi
    
    # 提交更改
    info "提交更改..."
    
    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] git add ."
        echo "[DRY RUN] git commit -m \"添加技能: $skill_id\""
        echo "[DRY RUN] git push origin $branch_name"
    else
        git add .
        git commit -m "添加技能: $skill_id"
        git push origin "$branch_name"
    fi
    
    # 创建Pull Request
    info "创建Pull Request..."
    
    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] gh pr create --title \"添加技能: $skill_id\" --body \"新技能提交\""
    else
        if command -v gh &> /dev/null; then
            gh pr create --title "添加技能: $skill_id" --body "新技能提交，请审核。" --fill
        else
            success "代码已推送到分支: $branch_name"
            echo ""
            echo "请手动创建Pull Request:"
            echo "1. 访问 https://github.com/guaidashu/openclaw-skill-hub"
            echo "2. 点击 'Pull requests' → 'New pull request'"
            echo "3. 选择分支: $branch_name"
            echo "4. 填写PR信息并创建"
        fi
    fi
    
    return 0
}

# 主函数
main() {
    local package_dir=""
    local manual_mode="false"
    local force="false"
    local github_token=""
    local dry_run="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--manual)
                manual_mode="true"
                shift
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            --github-token)
                github_token="$2"
                shift 2
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            -*)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                package_dir="$1"
                shift
                ;;
        esac
    done
    
    # 检查参数
    if [ -z "$package_dir" ]; then
        error "请指定技能包目录"
        show_help
        exit 1
    fi
    
    # 获取绝对路径
    package_dir=$(cd "$package_dir" && pwd 2>/dev/null || echo "$package_dir")
    
    # 验证技能包
    if ! validate_package "$package_dir" "$force"; then
        exit 1
    fi
    
    local skill_id
    skill_id=$(basename "$package_dir")
    
    log "提交技能包: $skill_id"
    log "模式: manual=$manual_mode, force=$force, dry-run=$dry_run"
    
    # 手动模式
    if [ "$manual_mode" = "true" ] || [ "$dry_run" = "true" ]; then
        generate_manual_guide "$package_dir" "$skill_id"
        
        if [ "$dry_run" = "true" ]; then
            info "试运行模式，不实际提交"
            echo ""
            info "将尝试自动提交（模拟）..."
            auto_submit_to_github "$package_dir" "$skill_id" "$github_token" "true"
        fi
        
        exit 0
    fi
    
    # 检查GitHub认证
    if ! check_github_token "$github_token"; then
        warning "将使用手动提交模式"
        generate_manual_guide "$package_dir" "$skill_id"
        exit 0
    fi
    
    # 自动提交
    info "尝试自动提交..."
    
    # 检查当前目录
    local current_dir
    current_dir=$(pwd)
    
    # 临时克隆仓库（如果不在仓库中）
    if [ ! -d ".git" ] || [[ ! $(git remote get-url origin 2>/dev/null) =~ openclaw-skill-hub ]]; then
        info "当前不在Skill Hub仓库中，需要克隆..."
        
        local temp_repo_dir="/tmp/skill-hub-submit-$(date +%s)"
        mkdir -p "$temp_repo_dir"
        cd "$temp_repo_dir"
        
        # 克隆仓库
        if [ -n "$github_token" ]; then
            git clone "https://$github_token@github.com/guaidashu/openclaw-skill-hub.git" . > /dev/null 2>&1
        elif [ -n "$GITHUB_TOKEN" ]; then
            git clone "https://$GITHUB_TOKEN@github.com/guaidashu/openclaw-skill-hub.git" . > /dev/null 2>&1
        else
            git clone "https://github.com/guaidashu/openclaw-skill-hub.git" . > /dev/null 2>&1
        fi
        
        if [ $? -ne 0 ]; then
            error "克隆仓库失败"
            cd "$current_dir"
            generate_manual_guide "$package_dir" "$skill_id"
            exit 1
        fi
        
        success "仓库克隆成功"
    fi
    
    # 执行自动提交
    if auto_submit_to_github "$package_dir" "$skill_id" "$github_token" "false"; then
        success "自动提交完成！"
        echo ""
        echo "下一步:"
        echo "1. 等待Pull Request审核"
        echo "2. 如有反馈，请及时修改"
        echo "3. 审核通过后技能将被合并"
    else
        error "自动提交失败"
        echo ""
        warning "将使用手动提交模式"
        generate_manual_guide "$package_dir" "$skill_id"
    fi
    
    # 返回原目录
    cd "$current_dir" 2>/dev/null || true
    
    return 0
}

# 异常处理
trap 'error "提交过程中断"; exit 1' INT TERM

# 运行主函数
main "$@"

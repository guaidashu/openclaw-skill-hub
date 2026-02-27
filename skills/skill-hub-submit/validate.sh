#!/bin/bash

# 技能验证脚本
# 验证技能目录是否符合OpenClaw Skill Hub标准

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
    echo "用法: validate.sh [选项] <技能目录>"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -v, --verbose  详细输出"
    echo "  -s, --strict   严格模式（所有警告视为错误）"
    echo ""
    echo "示例:"
    echo "  validate.sh ~/skills/weather"
    echo "  validate.sh -v ./my-skill"
}

# 检查必需文件
check_required_files() {
    local skill_dir="$1"
    local verbose="$2"
    
    local errors=0
    local warnings=0
    
    info "检查必需文件..."
    
    # 检查SKILL.md
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        error "缺少必需文件: SKILL.md"
        errors=$((errors + 1))
    else
        success "找到 SKILL.md"
        if [ "$verbose" = "true" ]; then
            echo "  文件大小: $(wc -l < "$skill_dir/SKILL.md") 行"
            echo "  文件内容前3行:"
            head -3 "$skill_dir/SKILL.md" | sed 's/^/    /'
        fi
    fi
    
    # 检查README.md（可选但推荐）
    if [ ! -f "$skill_dir/README.md" ]; then
        warning "推荐添加 README.md 文件"
        warnings=$((warnings + 1))
    else
        success "找到 README.md"
    fi
    
    # 检查目录非空
    local file_count
    file_count=$(find "$skill_dir" -type f -name "*.md" -o -name "*.sh" -o -name "*.json" | wc -l)
    if [ "$file_count" -lt 1 ]; then
        warning "技能目录可能为空或文件太少"
        warnings=$((warnings + 1))
    fi
    
    echo "文件检查: $errors 个错误, $warnings 个警告"
    return $errors
}

# 验证SKILL.md格式
validate_skill_md() {
    local skill_md="$1"
    local verbose="$2"
    
    local errors=0
    local warnings=0
    
    info "验证 SKILL.md 格式..."
    
    # 检查文件编码
    if ! file "$skill_md" | grep -q "UTF-8"; then
        warning "建议使用 UTF-8 编码"
        warnings=$((warnings + 1))
    fi
    
    # 检查必需字段
    local required_fields=("触发词" "描述" "作者" "版本")
    for field in "${required_fields[@]}"; do
        if ! grep -q "**$field**" "$skill_md"; then
            error "缺少必需字段: $field"
            errors=$((errors + 1))
        else
            if [ "$verbose" = "true" ]; then
                local field_value
                field_value=$(grep -A1 "**$field**" "$skill_md" | tail -1 | sed 's/^*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
                echo "  $field: $field_value"
            fi
        fi
    done
    
    # 检查版本格式
    if grep -q "**版本**" "$skill_md"; then
        local version_line
        version_line=$(grep -A1 "**版本**" "$skill_md" | tail -1)
        if ! echo "$version_line" | grep -qE "[0-9]+\.[0-9]+\.[0-9]+"; then
            warning "版本格式建议使用 x.x.x 格式"
            warnings=$((warnings + 1))
        fi
    fi
    
    # 检查文件大小
    local line_count
    line_count=$(wc -l < "$skill_md")
    if [ "$line_count" -lt 10 ]; then
        warning "SKILL.md 文件可能太短（$line_count 行）"
        warnings=$((warnings + 1))
    fi
    
    if [ "$line_count" -gt 500 ]; then
        warning "SKILL.md 文件可能太长（$line_count 行），考虑拆分"
        warnings=$((warnings + 1))
    fi
    
    echo "SKILL.md验证: $errors 个错误, $warnings 个警告"
    return $errors
}

# 检查文件权限
check_file_permissions() {
    local skill_dir="$1"
    
    local warnings=0
    
    info "检查文件权限..."
    
    # 检查脚本文件是否有执行权限
    find "$skill_dir" -name "*.sh" -type f | while read -r script; do
        if [ ! -x "$script" ]; then
            warning "脚本文件没有执行权限: $(basename "$script")"
            warnings=$((warnings + 1))
        else
            success "脚本文件有执行权限: $(basename "$script")"
        fi
    done
    
    # 检查目录权限
    if [ ! -r "$skill_dir" ]; then
        error "技能目录不可读"
        return 1
    fi
    
    if [ ! -w "$skill_dir" ]; then
        warning "技能目录不可写（可能影响打包）"
        warnings=$((warnings + 1))
    fi
    
    echo "权限检查: 0 个错误, $warnings 个警告"
    return 0
}

# 检查文件大小
check_file_sizes() {
    local skill_dir="$1"
    local max_size_mb="${2:-10}"  # 默认10MB
    
    local warnings=0
    
    info "检查文件大小（限制: ${max_size_mb}MB）..."
    
    # 检查总大小
    local total_size_kb
    total_size_kb=$(du -sk "$skill_dir" | cut -f1)
    local total_size_mb=$((total_size_kb / 1024))
    
    if [ "$total_size_mb" -gt "$max_size_mb" ]; then
        warning "技能目录太大: ${total_size_mb}MB > ${max_size_mb}MB"
        warnings=$((warnings + 1))
    else
        success "技能目录大小合适: ${total_size_mb}MB"
    fi
    
    # 检查单个大文件
    find "$skill_dir" -type f -size +5M 2>/dev/null | while read -r large_file; do
        local file_size_mb
        file_size_mb=$(( $(stat -f%z "$large_file" 2>/dev/null || stat -c%s "$large_file" 2>/dev/null) / 1024 / 1024 ))
        warning "发现大文件: $(basename "$large_file") (${file_size_mb}MB)"
        warnings=$((warnings + 1))
    done
    
    echo "大小检查: 0 个错误, $warnings 个警告"
    return 0
}

# 生成验证报告
generate_report() {
    local skill_dir="$1"
    local total_errors="$2"
    local total_warnings="$3"
    local verbose="$4"
    
    echo ""
    echo "="*60
    echo "技能验证报告"
    echo "="*60
    echo "技能目录: $skill_dir"
    echo "验证时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "验证结果: $total_errors 个错误, $total_warnings 个警告"
    echo ""
    
    if [ "$total_errors" -eq 0 ]; then
        if [ "$total_warnings" -eq 0 ]; then
            success "✅ 验证通过！技能格式符合标准。"
            echo ""
            echo "下一步建议:"
            echo "1. 使用 package.sh 打包技能"
            echo "2. 使用 submit.sh 提交技能到Skill Hub"
            echo "3. 或手动通过GitHub提交Pull Request"
        else
            warning "⚠ 验证通过，但有 $total_warnings 个警告。"
            echo ""
            echo "建议修复警告以提高技能质量。"
        fi
    else
        error "❌ 验证失败！发现 $total_errors 个错误。"
        echo ""
        echo "必须修复所有错误才能提交技能。"
        echo "常见错误及修复方法:"
        echo "1. 缺少 SKILL.md 文件 - 创建标准格式的SKILL.md"
        echo "2. SKILL.md格式错误 - 检查必需字段和格式"
        echo "3. 文件权限问题 - 确保文件可读可执行"
    fi
    
    echo ""
    echo "详细验证步骤:"
    echo "1. 必需文件检查 ✓"
    echo "2. SKILL.md格式验证 ✓"
    echo "3. 文件权限检查 ✓"
    echo "4. 文件大小检查 ✓"
    
    if [ "$verbose" = "true" ]; then
        echo ""
        echo "技能目录结构:"
        find "$skill_dir" -type f | sed "s|$skill_dir/||" | sort | while read -r file; do
            echo "  - $file"
        done
    fi
    
    echo "="*60
}

# 主函数
main() {
    local skill_dir=""
    local verbose="false"
    local strict="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -s|--strict)
                strict="true"
                shift
                ;;
            -*)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                skill_dir="$1"
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
    
    log "开始验证技能目录: $skill_dir"
    log "模式: verbose=$verbose, strict=$strict"
    
    local total_errors=0
    local total_warnings=0
    
    # 执行验证
    check_required_files "$skill_dir" "$verbose"
    total_errors=$((total_errors + $?))
    
    if [ -f "$skill_dir/SKILL.md" ]; then
        validate_skill_md "$skill_dir/SKILL.md" "$verbose"
        total_errors=$((total_errors + $?))
    fi
    
    check_file_permissions "$skill_dir"
    total_warnings=$((total_warnings + $?))
    
    check_file_sizes "$skill_dir"
    total_warnings=$((total_warnings + $?))
    
    # 严格模式：警告视为错误
    if [ "$strict" = "true" ] && [ "$total_warnings" -gt 0 ]; then
        error "严格模式：$total_warnings 个警告视为错误"
        total_errors=$((total_errors + total_warnings))
        total_warnings=0
    fi
    
    # 生成报告
    generate_report "$skill_dir" "$total_errors" "$total_warnings" "$verbose"
    
    # 返回状态码
    if [ "$total_errors" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# 异常处理
trap 'error "验证过程中断"; exit 1' INT TERM

# 运行主函数
main "$@"
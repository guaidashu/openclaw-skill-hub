#!/bin/bash

# OpenClaw Skill Hub 同步脚本
# 从GitHub仓库同步技能到本地

set -e

# 配置变量
REPO_URL="https://github.com/guaidashu/openclaw-skill-hub.git"
TEMP_DIR="/tmp/openclaw-skill-hub-$(date +%s)"
LOCAL_SKILL_DIR="$HOME/.openclaw/extensions/skill-hub"
LOCAL_REGISTRY="$LOCAL_SKILL_DIR/registry.json"
LOCAL_MEMBERS="$LOCAL_SKILL_DIR/members.json"
LOG_FILE="$HOME/.openclaw/logs/skill-sync-$(date +%Y%m%d).log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

# 检查依赖
check_dependencies() {
    local deps=("git" "curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "缺少依赖: ${missing[*]}"
        info "请安装缺失的依赖:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

# 创建目录
create_directories() {
    mkdir -p "$TEMP_DIR"
    mkdir -p "$LOCAL_SKILL_DIR/skills"
    mkdir -p "$LOCAL_SKILL_DIR/messages"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 初始化本地文件（如果不存在）
    if [ ! -f "$LOCAL_REGISTRY" ]; then
        echo '{"version":"0.0.0","skills":[]}' > "$LOCAL_REGISTRY"
    fi
    if [ ! -f "$LOCAL_MEMBERS" ]; then
        echo '{"version":"0.0.0","members":[]}' > "$LOCAL_MEMBERS"
    fi
}

# 克隆或更新仓库
update_repository() {
    if [ -d "$TEMP_DIR/.git" ]; then
        log "更新仓库..."
        cd "$TEMP_DIR"
        git pull origin main
    else
        log "克隆仓库..."
        git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
    fi
}

# 比较技能版本
compare_versions() {
    local remote_version="$1"
    local local_version="$2"
    
    if [ "$remote_version" == "$local_version" ]; then
        echo "same"
    elif [ "$remote_version" \> "$local_version" ]; then
        echo "newer"
    else
        echo "older"
    fi
}

# 同步技能
sync_skills() {
    local remote_registry="$TEMP_DIR/registry.json"
    local local_registry="$LOCAL_REGISTRY"
    
    if [ ! -f "$remote_registry" ]; then
        error "远程注册表不存在: $remote_registry"
        return 1
    fi
    
    # 读取远程技能列表
    local remote_skills
    remote_skills=$(jq -c '.skills[]' "$remote_registry")
    
    # 读取本地技能列表
    local local_skills
    if [ -f "$local_registry" ]; then
        local_skills=$(jq -c '.skills[]' "$local_registry" 2>/dev/null || echo '')
    else
        local_skills=""
    fi
    
    local updated=0
    local added=0
    
    # 处理每个远程技能
    while IFS= read -r skill; do
        local skill_id
        local skill_name
        local remote_version
        local local_version="0.0.0"
        
        skill_id=$(echo "$skill" | jq -r '.id')
        skill_name=$(echo "$skill" | jq -r '.name')
        remote_version=$(echo "$skill" | jq -r '.version')
        
        # 查找本地版本
        if [ -n "$local_skills" ]; then
            local_version=$(echo "$local_skills" | jq -r "select(.id == \"$skill_id\") | .version // \"0.0.0\"" | head -1)
            if [ -z "$local_version" ]; then
                local_version="0.0.0"
            fi
        fi
        
        # 比较版本
        local comparison
        comparison=$(compare_versions "$remote_version" "$local_version")
        
        case "$comparison" in
            "same")
                info "技能 '$skill_name' ($skill_id) 已是最新版本 v$remote_version"
                ;;
            "newer")
                info "更新技能 '$skill_name' ($skill_id): v$local_version → v$remote_version"
                copy_skill "$skill_id"
                update_local_registry "$skill"
                updated=$((updated + 1))
                ;;
            *)
                # 新技能
                info "新增技能 '$skill_name' ($skill_id) v$remote_version"
                copy_skill "$skill_id"
                update_local_registry "$skill"
                added=$((added + 1))
                ;;
        esac
    done <<< "$remote_skills"
    
    success "同步完成: 新增 $added 个技能, 更新 $updated 个技能"
}

# 复制技能文件
copy_skill() {
    local skill_id="$1"
    local remote_skill_dir="$TEMP_DIR/skills/$skill_id"
    local local_skill_dir="$LOCAL_SKILL_DIR/skills/$skill_id"
    
    if [ ! -d "$remote_skill_dir" ]; then
        warning "技能目录不存在: $remote_skill_dir"
        return
    fi
    
    # 创建本地目录
    mkdir -p "$local_skill_dir"
    
    # 复制文件
    cp -r "$remote_skill_dir"/* "$local_skill_dir/" 2>/dev/null || true
    
    # 设置权限
    chmod -R 755 "$local_skill_dir"
}

# 更新本地注册表
update_local_registry() {
    local skill_json="$1"
    local skill_id
    skill_id=$(echo "$skill_json" | jq -r '.id')
    
    # 读取本地注册表
    local registry_content
    if [ -f "$LOCAL_REGISTRY" ]; then
        registry_content=$(cat "$LOCAL_REGISTRY")
    else
        registry_content='{"version":"1.0.0","skills":[]}'
    fi
    
    # 更新或添加技能
    local updated_registry
    updated_registry=$(echo "$registry_content" | jq --argjson skill "$skill_json" '
        . as $registry |
        if any(.skills[]; .id == $skill.id) then
            .skills |= map(if .id == $skill.id then $skill else . end)
        else
            .skills += [$skill]
        end |
        .last_updated = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    ')
    
    echo "$updated_registry" > "$LOCAL_REGISTRY"
}

# 同步成员信息
sync_members() {
    local remote_members="$TEMP_DIR/members.json"
    local local_members="$LOCAL_MEMBERS"
    
    if [ ! -f "$remote_members" ]; then
        warning "远程成员文件不存在"
        return
    fi
    
    # 简单复制成员文件
    cp "$remote_members" "$local_members"
    info "成员信息已同步"
}

# 清理临时文件
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        info "临时文件已清理"
    fi
}

# 主函数
main() {
    log "开始同步OpenClaw Skill Hub..."
    
    # 检查依赖
    check_dependencies
    
    # 创建目录
    create_directories
    
    # 更新仓库
    update_repository
    
    # 同步技能
    sync_skills
    
    # 同步成员
    sync_members
    
    # 清理
    cleanup
    
    success "技能同步完成！"
    log "详细日志: $LOG_FILE"
}

# 异常处理
trap 'error "同步过程中断"; cleanup; exit 1' INT TERM
trap 'cleanup' EXIT

# 运行主函数
main "$@"
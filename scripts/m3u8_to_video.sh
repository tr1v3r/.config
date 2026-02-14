#!/bin/bash

# ============================================================================
# m3u8_to_video.sh - 生产级可靠版 (增加完整性校验与慢速重试)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEMP_DIR="ts_segments"
MAX_RETRIES=5      # 增加重试次数
TIMEOUT=20
PARALLEL_DOWNLOADS=4 # 降低默认并发，提高成功率
KEEP_SEGMENTS=false

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--parallel) PARALLEL_DOWNLOADS="$2"; shift 2 ;;
            -b|--base-url) BASE_URL="$2"; shift 2 ;;
            -t|--temp-dir) TEMP_DIR="$2"; shift 2 ;;
            -k|--keep) KEEP_SEGMENTS=true; shift ;;
            *)
                if [[ -z "$M3U8_FILE" ]]; then M3U8_FILE="$1";
                elif [[ -z "$OUTPUT_FILE" ]]; then OUTPUT_FILE="$1";
                fi; shift ;;
        esac
    done
    [[ -z "$M3U8_FILE" ]] && error "需要指定 m3u8 文件"
    [[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="video.mp4"
    ABS_OUTPUT_FILE="$(cd "$(dirname ".")" && pwd)/$OUTPUT_FILE"
}

prepare_urls() {
    log "解析播放列表..."
    mkdir -p "$TEMP_DIR"
    
    # 支持从 URL 直接获取 m3u8
    if [[ "$M3U8_FILE" =~ ^https?:// ]]; then
        curl -L -f -s -o "$TEMP_DIR/playlist.m3u8" "$M3U8_FILE"
        M3U8_PATH="$TEMP_DIR/playlist.m3u8"
        # 如果未指定 BASE_URL，则自动推断
        [[ -z "$BASE_URL" ]] && BASE_URL="${M3U8_FILE%/*}"
    else
        M3U8_PATH="$M3U8_FILE"
    fi

    grep -v '^#' "$M3U8_PATH" | grep -v '^[[:space:]]*$' > "$TEMP_DIR/raw_list.txt"
    local i=0
    rm -f "$TEMP_DIR/download_tasks.txt"
    while read -r line; do
        local segment_url="$line"
        if [[ ! "$line" =~ ^https?:// ]]; then
            segment_url="${BASE_URL%/}/${line#/}"
        fi
        printf "%s\t%05d\n" "$segment_url" "$i" >> "$TEMP_DIR/download_tasks.txt"
        ((i++))
    done < "$TEMP_DIR/raw_list.txt"
    TOTAL_SEGMENTS=$i
    log "发现 $TOTAL_SEGMENTS 个分片"
}

download_all() {
    log "开始下载分片 (并发: $PARALLEL_DOWNLOADS)..."
    export TEMP_DIR MAX_RETRIES TIMEOUT RED GREEN YELLOW NC
    
    # 进度显示函数 (后台运行)
    show_progress() {
        local total=$1
        local bar_size=40
        while true; do
            local current=$(find "$TEMP_DIR" -name "segment_*.ts" -size +0c 2>/dev/null | wc -l | tr -d ' ')
            local percent=$(( current * 100 / total ))
            local filled=$(( current * bar_size / total ))
            local empty=$(( bar_size - filled ))
            
            local bar=""
            [[ $filled -gt 0 ]] && bar=$(printf "%${filled}s" | tr " " "█")
            local e_bar=""
            [[ $empty -gt 0 ]] && e_bar=$(printf "%${empty}s" | tr " " "░")
            
            printf "\r${BLUE}[INFO]${NC} 下载进度: [${bar}${e_bar}] %d/%d (%d%%)" "$current" "$total" "$percent"
            [[ $current -ge $total ]] && break
            sleep 0.5
        done
        echo ""
    }

    # 启动进度条
    show_progress "$TOTAL_SEGMENTS" &
    local progress_pid=$!

    # 使用 xargs 并行下载
    cat "$TEMP_DIR/download_tasks.txt" | xargs -P "$PARALLEL_DOWNLOADS" -n 2 bash -c '
        url=$0; index=$1; output="$TEMP_DIR/segment_$index.ts"
        if [[ -s "$output" ]]; then exit 0; fi 
        
        retries=0
        while [[ $retries -lt $MAX_RETRIES ]]; do
            if curl -L -f -s --max-time "$TIMEOUT" -A "Mozilla/5.0" -o "$output" "$url"; then
                exit 0
            fi
            ((retries++))
            sleep 0.5
        done
        exit 1
    ' || true

    wait $progress_pid 2>/dev/null || true
    echo ""

    # 检查是否有缺失或空文件
    local missing=0
    for ((i=0; i<TOTAL_SEGMENTS; i++)); do
        local idx=$(printf "%05d" $i)
        if [[ ! -s "$TEMP_DIR/segment_$idx.ts" ]]; then
            warn "分片 $idx 下载失败"
            ((missing++))
        fi
    done

    if [[ $missing -gt 0 ]]; then
        error "共有 $missing 个分片下载失败。请尝试调低并发 (-p 2) 或检查网络。"
    fi
}

merge_video() {
    log "正在物理拼接分片..."
    local combined_ts="$TEMP_DIR/combined_all.ts"
    rm -f "$combined_ts"
    
    # 按照编号顺序拼接
    find "$TEMP_DIR" -name "segment_*.ts" | sort | xargs cat >> "$combined_ts"
    
    log "正在重封装并修复时间戳..."
    # 这一步非常关键：使用 ffmpeg 重新扫描整个流并生成连续的时间戳
    ffmpeg -y -i "$combined_ts" -c copy -bsf:a aac_adtstoasc -fflags +genpts "$ABS_OUTPUT_FILE"
    
    if [[ -f "$ABS_OUTPUT_FILE" ]]; then
        success "视频已成功生成: $OUTPUT_FILE"
    else
        error "合并失败"
    fi
}

cleanup() {
    if ! $KEEP_SEGMENTS; then
        rm -rf "$TEMP_DIR"
    fi
}

main() {
    parse_args "$@"
    prepare_urls
    download_all
    merge_video
    cleanup
}

main "$@"

#!/bin/bash

# NoCodeBackend Video Learning Pipeline - LEAN VERSION
# Processes one video at a time with immediate cleanup to minimize disk usage

set -e  # Exit on error

LINKS_FILE="/Users/kcdacre8tor/Downloads/NoCodeBackendlinks.txt"
DOWNLOAD_DIR="$HOME/xtractedyt"
FRAMES_BASE_DIR="$DOWNLOAD_DIR/frames"
NOCODEBACKEND_DIR="$FRAMES_BASE_DIR/NoCodeBackend"
ANALYSIS_DIR="$NOCODEBACKEND_DIR/analysis"
LOG_FILE="$NOCODEBACKEND_DIR/processing.log"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create directories
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$NOCODEBACKEND_DIR"
mkdir -p "$ANALYSIS_DIR"

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Extract YouTube video ID from URL
get_video_id() {
    local url="$1"
    if [[ $url =~ youtube\.com/watch\?v=([^&]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ $url =~ youtu\.be/([^?]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Check available disk space
check_disk_space() {
    local available=$(df -h "$HOME" | tail -1 | awk '{print $4}')
    local available_gb=$(df -g "$HOME" | tail -1 | awk '{print $4}')

    log "Available disk space: $available"

    if [ "$available_gb" -lt 2 ]; then
        error "Less than 2GB available. Need at least 2GB for safe processing."
        return 1
    fi

    return 0
}

# Process a single video: download, extract frames, cleanup
process_single_video() {
    local url="$1"
    local index="$2"
    local total="$3"

    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Processing Video [$index/$total]"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check disk space before starting
    if ! check_disk_space; then
        error "Insufficient disk space. Please free up space and try again."
        return 1
    fi

    local video_id=$(get_video_id "$url")
    if [ -z "$video_id" ]; then
        error "Could not extract video ID from URL: $url"
        return 1
    fi

    # Check if frames already exist
    local existing_dir=$(find "$NOCODEBACKEND_DIR" -type d -name "*${video_id}*" | head -1)
    if [ -n "$existing_dir" ]; then
        local existing_frames=$(ls "$existing_dir"/*.png 2>/dev/null | wc -l)
        if [ "$existing_frames" -gt 10 ]; then
            success "Frames already extracted for video $video_id ($existing_frames frames). Skipping."
            return 0
        fi
    fi

    # STEP 1: Download video
    log "Step 1/3: Downloading video $video_id..."

    local timestamp=$(date +%s)
    local output_path="$DOWNLOAD_DIR/${timestamp}-NoCodeBackend-${index}-${video_id}"

    yt-dlp \
        -f "bestvideo[height<=720]+bestaudio/best[height<=720]" \
        -o "${output_path}.%(ext)s" \
        --merge-output-format mp4 \
        --no-check-certificates \
        --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        --add-header "Accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        "$url" 2>&1 | tee -a "$LOG_FILE"

    # Find the downloaded file
    local downloaded_file=$(ls "$DOWNLOAD_DIR" | grep "^${timestamp}-NoCodeBackend-${index}" | head -1)
    if [ -z "$downloaded_file" ]; then
        error "Failed to find downloaded file for $url"
        return 1
    fi

    local video_path="$DOWNLOAD_DIR/$downloaded_file"
    local video_size=$(du -h "$video_path" | cut -f1)
    success "Downloaded: $downloaded_file (Size: $video_size)"

    # STEP 2: Extract frames
    log "Step 2/3: Extracting frames..."

    local video_basename=$(basename "$video_path" .mp4)
    local frames_output_dir="$NOCODEBACKEND_DIR/$video_basename"
    mkdir -p "$frames_output_dir"

    # Get video duration
    local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_path")
    local duration_int=${duration%.*}

    # Calculate interval for 75 frames
    local target_frames=75
    local interval=$((duration_int / target_frames))
    if [ "$interval" -lt 1 ]; then
        interval=1
    fi

    log "Video duration: ${duration_int}s, extracting 1 frame every ${interval}s"

    # Extract frames
    ffmpeg -i "$video_path" \
        -vf "fps=1/${interval}" \
        -q:v 2 \
        "$frames_output_dir/frame_%04d.png" \
        -y 2>&1 | grep -E "frame=|time=|speed=" | tee -a "$LOG_FILE"

    local frame_count=$(ls "$frames_output_dir"/*.png 2>/dev/null | wc -l)
    success "Extracted $frame_count frames to: $frames_output_dir"

    # STEP 3: Delete video to free space
    log "Step 3/3: Cleaning up video file..."

    rm -f "$video_path"
    success "Deleted video file, freed $video_size"

    # Show disk space after cleanup
    local available_after=$(df -h "$HOME" | tail -1 | awk '{print $4}')
    log "Available disk space after cleanup: $available_after"

    log "✅ Video $index/$total complete: $frame_count frames extracted"
    echo ""

    return 0
}

# Main processing pipeline
main() {
    log "============================================="
    log "NoCodeBackend LEAN Processing Pipeline"
    log "Processing one video at a time with auto-cleanup"
    log "============================================="

    # Check dependencies
    for cmd in yt-dlp ffmpeg ffprobe; do
        if ! command -v $cmd &> /dev/null; then
            error "$cmd is not installed. Please install it first."
            exit 1
        fi
    done

    # Initial disk space check
    if ! check_disk_space; then
        error "Insufficient disk space to begin. Please free up space first."
        exit 1
    fi

    # Read URLs from file (compatible with bash 3.2+)
    urls=()
    while IFS= read -r line; do
        if [[ $line =~ youtube ]]; then
            urls+=("$line")
        fi
    done < "$LINKS_FILE"
    local total_videos=${#urls[@]}

    log "Found $total_videos YouTube URLs to process"
    log ""

    # Track successful processing
    local success_count=0
    local failed_count=0
    declare -a failed_videos

    # Process each video one at a time
    local index=1
    for url in "${urls[@]}"; do
        if process_single_video "$url" "$index" "$total_videos"; then
            success_count=$((success_count + 1))
        else
            failed_count=$((failed_count + 1))
            failed_videos+=("Video $index: $url")
        fi

        index=$((index + 1))

        # Brief pause between videos
        if [ "$index" -le "$total_videos" ]; then
            log "Waiting 3 seconds before next video..."
            sleep 3
        fi
    done

    # Create frame inventory
    log ""
    log "============================================="
    log "Creating Frame Inventory"
    log "============================================="

    local inventory_file="$NOCODEBACKEND_DIR/FRAME_INVENTORY.md"
    cat > "$inventory_file" <<EOF
# NoCodeBackend Tutorial Frame Inventory

**Generated:** $(date)
**Videos Processed:** $success_count successful, $failed_count failed
**Total Videos:** $total_videos
**Base Directory:** $NOCODEBACKEND_DIR

---

## Processing Summary

EOF

    if [ "$failed_count" -gt 0 ]; then
        echo "### ⚠️ Failed Videos" >> "$inventory_file"
        echo "" >> "$inventory_file"
        for failed in "${failed_videos[@]}"; do
            echo "- $failed" >> "$inventory_file"
        done
        echo "" >> "$inventory_file"
    fi

    echo "### ✅ Successfully Processed Frame Directories" >> "$inventory_file"
    echo "" >> "$inventory_file"

    local total_frames=0
    for frames_dir in "$NOCODEBACKEND_DIR"/*/; do
        if [ -d "$frames_dir" ] && [ "$(basename "$frames_dir")" != "analysis" ] && [ "$(basename "$frames_dir")" != "knowledge_base" ]; then
            local dir_name=$(basename "$frames_dir")
            local frame_count=$(ls "$frames_dir"/*.png 2>/dev/null | wc -l)

            if [ "$frame_count" -gt 0 ]; then
                total_frames=$((total_frames + frame_count))
                echo "- **$dir_name**: $frame_count frames" >> "$inventory_file"
                echo "  - Path: \`$frames_dir\`" >> "$inventory_file"
            fi
        fi
    done

    cat >> "$inventory_file" <<EOF

---

## Summary

- **Successfully Processed:** $success_count videos
- **Failed:** $failed_count videos
- **Total Frames Extracted:** $total_frames
- **Average Frames per Video:** $((total_frames / success_count))
- **Disk Space Used:** Minimal (videos deleted after frame extraction)

---

## Next Steps

1. Run knowledge base builder: \`python3 build_nocodebackend_knowledge.py\`
2. Analyze frames with Claude Code
3. Build memvid knowledge base for semantic search

EOF

    success "Created frame inventory: $inventory_file"

    # Final summary
    log ""
    log "============================================="
    log "PROCESSING COMPLETE"
    log "============================================="
    log "✅ Successfully processed: $success_count videos"
    log "❌ Failed: $failed_count videos"
    log "📊 Total frames extracted: $total_frames"
    log "📁 Output directory: $NOCODEBACKEND_DIR"
    log "📄 Inventory: $inventory_file"
    log "📋 Log file: $LOG_FILE"

    local final_space=$(df -h "$HOME" | tail -1 | awk '{print $4}')
    log "💾 Available disk space: $final_space"

    log ""
    log "Next: Run the knowledge base builder"
    log "  python3 build_nocodebackend_knowledge.py"
}

# Run main pipeline
main

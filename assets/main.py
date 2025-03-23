# main.py
import json
import os
import yt_dlp
import argparse
from concurrent.futures import ThreadPoolExecutor
from yt_dlp.utils import sanitize_filename
from urllib.parse import urlparse, parse_qs
import sys

# Config
DEFAULT_OUTPUT_DIR = os.path.expanduser("~/Downloads/youtube-downloader")
MAX_WORKERS = 4
SUPPORTED_FORMATS = ["video", "audio", "info-only"]
SUPPORTED_AUDIO_FORMATS = ["mp3", "m4a", "wav", "flac"]
DEFAULT_AUDIO_FORMAT = "mp3"
DEFAULT_VIDEO_QUALITY = "720p"

# Utils
def log_info(message):
    sys.stdout.write(f"{message}\n")
    sys.stdout.flush()
    

class VideoDownloadException(Exception):
    def __init__(self, message):
        log_info(f"VideoDownloadException: {message}")
        super().__init__(message)

def ensure_directory_exists(directory=DEFAULT_OUTPUT_DIR):
    os.makedirs(directory, exist_ok=True)

# Info Extractor
def extract_info(url, extract_flat=False):
    ydl_opts = {"quiet": True}
    if extract_flat:
        ydl_opts["extract_flat"] = True
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            return ydl.extract_info(url, download=False)
    except yt_dlp.utils.ExtractorError as e:
        log_info(f"Failed to extract info from {url}: {e}")
        raise VideoDownloadException(f"Cannot extract information from {url}")

def get_video_info(video_url):
    log_info(f"Fetching info for URL: {video_url}")
    parsed_url = urlparse(video_url)
    query_params = parse_qs(parsed_url.query)
    playlist_id = query_params.get("list", [None])[0]

    if playlist_id:
        playlist_url = f"https://www.youtube.com/playlist?list={playlist_id}"
        info = extract_info(playlist_url, extract_flat=True)
        playlist_videos = [
            {
                "title": entry.get("title", "Untitled"),
                "url": entry["url"],
                "duration": entry.get("duration", 0),
                "thumbnail": entry.get("thumbnails", [{}])[0].get("url", "") if entry.get("thumbnails") else ""
            }
            for entry in info["entries"] if "url" in entry
        ]
        log_info(f"START_INFO:{json.dumps(playlist_videos)}:END_INFO")
        return playlist_videos
    else:
        info = extract_info(video_url)
        video_info = {
            "id": info.get("id", ""),
            "title": info.get("title", "Untitled"),
            "duration": info.get("duration", 0),
            "thumbnail": info.get("thumbnails", [{}])[0].get("url", "") if info.get("thumbnails") else "",
            "url": video_url
        }
        log_info(f"START_INFO:{json.dumps(video_info)}:END_INFO")
        return video_info

# Downloader
def progress_hook(d):
    progress_data = {
        "id": d["info_dict"]["id"],
        "title": d["info_dict"]["title"],
        "duration": d["info_dict"]["duration"],
        "thumbnail": d["info_dict"]["thumbnails"][0]["url"],
        "url": d["info_dict"]["url"],
        "status": d["status"],
        "percent": d["_percent_str"],
        "total_bytes": d.get("total_bytes", "unknown")
    }
    if d["status"] == "finished":
        progress_data["percent"] = "100%"
        progress_data["status"] = "completed"
    
    log_info(f"START_INFO:{json.dumps(progress_data)}:END_INFO")

def get_download_options(format_type, audio_format, video_quality, output_template):
    if format_type not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported format: {format_type}")
    if format_type == "audio" and audio_format not in SUPPORTED_AUDIO_FORMATS:
        raise ValueError(f"Unsupported audio format: {audio_format}")

    base_options = {
        "outtmpl": output_template,
        "quiet": True,
        "embedthumbnail": True,
        "nooverwrites": True,
        "progress_hooks": [progress_hook],
        "noprogress": True,
    }
    if format_type == "video":
        format_str = "bestvideo+bestaudio" if video_quality == "best" else f"bestvideo[height<={int(video_quality.replace('p', ''))}]+bestaudio"
        base_options.update({
            "format": format_str,
            "merge_output_format": "mkv",
        })
    elif format_type == "audio":
        base_options.update({
            "format": "bestaudio/best",
            "postprocessors": [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": audio_format,
                "preferredquality": "0",
            }],
        })
    return base_options

def download_video(video_url, format_type="video", audio_format=DEFAULT_AUDIO_FORMAT, video_quality=DEFAULT_VIDEO_QUALITY, output_dir=None):
    log_info(f"Starting download for: {video_url}")
    try:
        info = get_video_info(video_url)
        if not info:
            raise VideoDownloadException("Cannot get video information.")
        
        video_title = sanitize_filename(info.get("title", "video"))
        output_template = os.path.join(output_dir, f"{video_title}")
        file_extension = "mkv" if format_type == "video" else audio_format
        expected_output_path = f"{output_template}.{file_extension}"

        if os.path.exists(expected_output_path):
            log_info(f"File already exists: {expected_output_path}. Skipping download.")
            return
        
        ydl_opts = get_download_options(format_type, audio_format, video_quality, output_template)
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([video_url])
        log_info(f"Download completed: {expected_output_path}")
    except Exception as e:
        log_info(f"Error downloading {video_url}: {e}")

# Main
def main():
    parser = argparse.ArgumentParser(description="YouTube Downloader using yt-dlp")
    parser.add_argument("urls", nargs="+", help="List of video or playlist URLs")
    parser.add_argument("--format", choices=SUPPORTED_FORMATS, default="video", 
                        help="Download as video, audio, or only fetch info")
    parser.add_argument("--audio-format", choices=SUPPORTED_AUDIO_FORMATS, default=DEFAULT_AUDIO_FORMAT)
    parser.add_argument("--quality", default=DEFAULT_VIDEO_QUALITY, help="Video quality (e.g., 1080p, 720p, best)")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help="Output directory")

    args = parser.parse_args()
    ensure_directory_exists(args.output_dir)

    log_info("Starting YouTube Downloader")
    if args.format == "info-only":
        for url in args.urls:
            get_video_info(url)
    else:
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            executor.map(lambda url: download_video(url, args.format, args.audio_format, args.quality, args.output_dir), args.urls)

if __name__ == "__main__":
    main()
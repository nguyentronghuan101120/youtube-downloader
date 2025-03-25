import json
import os
import yt_dlp
import argparse
from concurrent.futures import ThreadPoolExecutor
from yt_dlp.utils import sanitize_filename
from urllib.parse import urlparse, parse_qs
import sys

# Config
CONFIG = {
    "default_output_dir": os.path.expanduser("~/Downloads/youtube-downloader"),
    "max_workers": 4,
    "supported_formats": ["video", "audio", "info-only"],
    "supported_audio_formats": ["mp3", "m4a", "wav", "flac"],
    "default_audio_format": "mp3",
    "default_video_quality": "720p",
}

def log_info(message):
    sys.stdout.write(f"{message}\n")
    sys.stdout.flush()

def log_error(message):
    sys.stderr.write(f"ERROR: {message}\n")
    sys.stderr.flush()

class VideoDownloadException(Exception):
    def __init__(self, message):
        log_error(message)
        super().__init__(message)

def ensure_directory_exists(directory):
    os.makedirs(directory, exist_ok=True)

def extract_info(url, extract_flat=False):
    ydl_opts = {"quiet": True}
    if extract_flat:
        ydl_opts["extract_flat"] = True
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            return ydl.extract_info(url, download=False)
    except yt_dlp.utils.ExtractorError as e:
        raise VideoDownloadException(f"Cannot extract information from {url}: {str(e)}")

def get_video_info(video_url):
    parsed_url = urlparse(video_url)
    query_params = parse_qs(parsed_url.query)
    playlist_id = query_params.get("list", [None])[0]

    if playlist_id:
        playlist_url = f"https://www.youtube.com/playlist?list={playlist_id}"
        info = extract_info(playlist_url, extract_flat=True)
        playlist_videos = [
            {
                "id": entry.get("id", ""),
                "status": "not_downloaded",
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
            "status": "not_downloaded",
            "duration": info.get("duration", 0),
            "thumbnail": info.get("thumbnails", [{}])[0].get("url", "") if info.get("thumbnails") and len(info.get("thumbnails")) > 0 else "",
            "url": video_url
        }
        log_info(f"START_INFO:{json.dumps(video_info)}:END_INFO")
        return video_info

def progress_hook(d):
    progress_data = {
        "id": d["info_dict"]["id"],
        "status": d["status"] ,
        "percent": d["_percent_str"].replace("%", ""),
        "total_bytes": d.get("total_bytes", "unknown")
    }

    log_info(f"START_INFO:{json.dumps(progress_data)}:END_INFO")

def get_download_options(format_type, audio_format, video_quality, output_template):
    if format_type not in CONFIG["supported_formats"]:
        raise ValueError(f"Unsupported format: {format_type}")
    if format_type == "audio" and audio_format not in CONFIG["supported_audio_formats"]:
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

def download_video(video_url, format_type="video", audio_format=CONFIG["default_audio_format"], 
                  video_quality=CONFIG["default_video_quality"], output_dir=None):
    log_info(f"Starting download for: {video_url}")
    try:
        info = get_video_info(video_url) if isinstance(video_url, str) else video_url
        if not info:
            raise VideoDownloadException("Cannot get video information.")

        video_title = sanitize_filename(info.get("title", "video"))
        output_template = os.path.join(output_dir, f"{video_title}")
        file_extension = "mkv" if format_type == "video" else audio_format
        expected_output_path = f"{output_template}.{file_extension}"

        if os.path.exists(expected_output_path):
            video_info = {
                "id": info.get("id", ""),
                "status": "finished",
                "output_path": expected_output_path
            }
            log_info(f"START_INFO:{json.dumps(video_info)}:END_INFO")
            return

        ydl_opts = get_download_options(format_type, audio_format, video_quality, output_template)
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([video_url])
        log_info(f"Download completed: {expected_output_path}")
    except Exception as e:
        log_error(f"Error downloading {video_url}: {str(e)}")
        raise

def main():
    parser = argparse.ArgumentParser(description="YouTube Downloader using yt-dlp")
    parser.add_argument("urls", nargs="+", help="List of video or playlist URLs")
    parser.add_argument("--format", choices=CONFIG["supported_formats"], default="video")
    parser.add_argument("--audio-format", choices=CONFIG["supported_audio_formats"], default=CONFIG["default_audio_format"])
    parser.add_argument("--quality", default=CONFIG["default_video_quality"], help="Video quality (e.g., 1080p, 720p, best)")
    parser.add_argument("--output-dir", default=CONFIG["default_output_dir"], help="Output directory")
    parser.add_argument("--max-workers", type=int, default=CONFIG["max_workers"], help="Max concurrent downloads")

    args = parser.parse_args()
    ensure_directory_exists(args.output_dir)

    log_info("Starting YouTube Downloader")
    if args.format == "info-only":
        for url in args.urls:
            get_video_info(url)
    else:
        with ThreadPoolExecutor(max_workers=args.max_workers) as executor:
            executor.map(
                lambda url: download_video(url, args.format, args.audio_format, args.quality, args.output_dir),
                args.urls
            )

if __name__ == "__main__":
    main()
# -*- coding: utf-8 -*-

import os
import yt_dlp
import argparse
import logging
from concurrent.futures import ThreadPoolExecutor
from yt_dlp.utils import sanitize_filename
from urllib.parse import urlparse, parse_qs

# Configure logging with consistent levels
logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# Default output directory
DEFAULT_OUTPUT_DIR = os.path.expanduser("~/Downloads/youtube-downloader")

class VideoDownloadException(Exception):
    """Custom exception for video download errors."""
    pass

def extract_info(url, extract_flat=False):
    """Extract metadata from a URL without downloading."""
    ydl_opts = {"quiet": True}
    if extract_flat:
        ydl_opts["extract_flat"] = True
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            return ydl.extract_info(url, download=False)
    except yt_dlp.utils.ExtractorError as e:
        logger.error(f"Failed to extract info from {url}: {e}")
        raise VideoDownloadException(f"Cannot extract information from {url}")

def get_video_info(video_url):
    """Determine if URL is a playlist or single video and return appropriate info."""
    logger.info(f"Fetching info for URL: {video_url}")
    parsed_url = urlparse(video_url)
    query_params = parse_qs(parsed_url.query)
    playlist_id = query_params.get('list', [None])[0]

    if playlist_id:
        playlist_url = f"https://www.youtube.com/playlist?list={playlist_id}"
        info = extract_info(playlist_url, extract_flat=True)
        playlist_videos = [{'title': entry.get('title', 'Untitled'), 'url': entry['url']} 
                           for entry in info['entries'] if 'url' in entry]
        logger.info(f"Detected playlist '{info.get('title', 'Unnamed playlist')}' with {len(playlist_videos)} videos")
        return playlist_videos
    else:
        info = extract_info(video_url)
        logger.info(f"Single video detected: {info.get('title', 'Untitled')}")
        return info

def get_download_options(format_type, audio_format, video_quality, output_template):
    """Generate yt-dlp options based on download type and quality."""
    base_options = {
        'outtmpl': output_template,  # No manual extension; yt-dlp will handle it
        'quiet': True,
        'embedthumbnail': True,
        'nooverwrites': True,  # Prevent overwriting existing files
    }
    if format_type == "video":
        format_str = 'bestvideo+bestaudio' if video_quality == "best" else f'bestvideo[height<={int(video_quality.replace("p", ""))}]+bestaudio'
        base_options.update({
            'format': format_str,
            'merge_output_format': 'mkv',
        })
    else:  # Audio
        base_options.update({
            'format': 'bestaudio/best',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': audio_format,
                'preferredquality': '0',
            }],
        })
    return base_options

def download_video(video_name,video_url, format_type="video", audio_format="mp3", video_quality="720p", output_dir=None):
    """Download a single video or audio file from YouTube."""
    logger.info(f"Starting download for: {video_name}")
    try:
        info = extract_info(video_url)
        if not info:
            raise VideoDownloadException("Cannot get video information.")
        
        video_title = sanitize_filename(info.get("title", "video"))
        output_template = os.path.join(output_dir, f"{video_title}")  # Base name without extension
        file_extension = "mkv" if format_type == "video" else audio_format
        expected_output_path = f"{output_template}.{file_extension}"

        # Check if file already exists (additional safety check)
        if os.path.exists(expected_output_path):
            logger.info(f"File already exists: {expected_output_path}. Skipping download.")
            return
        
        ydl_opts = get_download_options(format_type, audio_format, video_quality, output_template)
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([video_url])
        logger.info(f"Download completed: {expected_output_path}")
    except Exception as e:
        logger.error(f"Error downloading {video_url}: {e}")

def process_url(url, format_type, audio_format, video_quality, output_dir):
    """Process a URL, handling both single videos and playlists with user selection."""
    info = get_video_info(url)
    if isinstance(info, list):  # Playlist
        print("\nPlaylist detected. Available videos:")
        for i, video in enumerate(info):
            print(f"{i + 1}. {video['title']}")
        
        print("\nEnter video numbers to download (e.g., '1 3 5'), or 'all' to download all:")
        user_input = input("> ").strip().lower()
        
        selected_urls = []
        if user_input == "all":
            selected_urls = [video['url'] for video in info]
        else:
            try:
                indices = [int(x) - 1 for x in user_input.split()]
                selected_urls = [info[i]['url'] for i in indices if 0 <= i < len(info)]
            except (ValueError, IndexError):
                logger.error("Invalid input. Skipping playlist.")
                return
        
        if not selected_urls:
            logger.info("No valid videos selected. Skipping playlist.")
            return
        
        with ThreadPoolExecutor(max_workers=4) as executor:
            executor.map(lambda u: download_video(info.get("title", "video"), u, format_type, audio_format, video_quality, output_dir), selected_urls)
            logger.info(f"All selected downloads for playlist {url} submitted")
    else:  # Single video
        download_video(info.get("title", "video"), url, format_type, audio_format, video_quality, output_dir)

def main():
    """Main entry point for the YouTube Downloader."""
    parser = argparse.ArgumentParser(description="YouTube Downloader using yt-dlp")
    parser.add_argument("urls", nargs='+', help="List of video or playlist URLs")
    parser.add_argument("--format", choices=["video", "audio"], default="video", help="Download as video or audio")
    parser.add_argument("--audio-format", choices=["mp3", "m4a", "wav", "flac"], default="mp3", 
                        help="Audio format (flac recommended for lossless quality)")
    parser.add_argument("--quality", default="720p", help="Video quality (e.g., 1080p, 720p, best)")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help="Output directory")
    
    args = parser.parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    
    logger.info("Starting YouTube Downloader")
    for url in args.urls:
        process_url(url, args.format, args.audio_format, args.quality, args.output_dir)

if __name__ == "__main__":
    main()
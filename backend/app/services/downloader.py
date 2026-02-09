import yt_dlp
import asyncio
from typing import Dict, Any, List
from app.core.config import get_settings

settings = get_settings()

class YtDlpService:
    def __init__(self):
        self.common_opts = {
            'quiet': True,
            'no_warnings': True,
            'ignoreerrors': True,
        }

    async def get_video_info(self, url: str) -> Dict[str, Any]:
        """
        Fetches metadata for a given YouTube URL using yt-dlp.
        Running in an executor to avoid blocking the async loop.
        """
        def _fetch_info():
            opts = {**self.common_opts, 'extract_flat': 'in_playlist'}
            with yt_dlp.YoutubeDL(opts) as ydl:
                return ydl.extract_info(url, download=False)

        loop = asyncio.get_event_loop()
        try:
            # yt-dlp is synchronous, so we run it in a thread
            info = await loop.run_in_executor(None, _fetch_info)
            return self._process_info(info)
        except Exception as e:
            # Re-raise or handle specific yt-dlp errors
            raise Exception(f"Failed to fetch video info: {str(e)}")

    def _process_info(self, info: Dict[str, Any]) -> Dict[str, Any]:
        """
        Clean up and format the info dictionary for the frontend.
        """
        if not info:
            return {}
            
        # Check if it's a playlist
        if info.get('_type') == 'playlist':
            return {
                "type": "playlist",
                "id": info.get("id"),
                "title": info.get("title"),
                "uploader": info.get("uploader"),
                "webpage_url": info.get("webpage_url"),
                "entries": [
                    {
                        "id": entry.get("id"),
                        "title": entry.get("title"),
                        "duration": entry.get("duration"),
                        "thumbnail": entry.get("thumbnails")[0].get("url") if entry.get("thumbnails") else None,
                        "uploader": entry.get("uploader"),
                         "url": entry.get("url")
                    }
                    for entry in info.get("entries", []) if entry
                ]
            }

        # Basic Info (Single Video)
        video_data = {
            "type": "video",
            "id": info.get("id"),
            "title": info.get("title"),
            "uploader": info.get("uploader"),
            "duration": info.get("duration"),
            "thumbnail": info.get("thumbnail"),
            "view_count": info.get("view_count"),
            "webpage_url": info.get("webpage_url"),
            "is_live": info.get("is_live", False),
            "formats": []
        }

        # Filter and organize formats (if available)
        formats = info.get("formats", [])
        processed_formats = []
        
        for f in formats:
            # Basic validation to ensure we have resolution and ext
            if f.get("vcodec") != "none" and f.get("acodec") == "none": # Video only
                 processed_formats.append({
                    "format_id": f.get("format_id"),
                    "ext": f.get("ext"),
                    "resolution": f.get("resolution"),
                    "filesize": f.get("filesize"),
                    "video_ext": f.get("video_ext"),
                    "height": f.get("height"),
                    "note": f.get("format_note"),
                    "type": "video"
                })
            elif f.get("vcodec") == "none" and f.get("acodec") != "none": # Audio only
                processed_formats.append({
                    "format_id": f.get("format_id"),
                    "ext": f.get("ext"),
                    "filesize": f.get("filesize"),
                    "abr": f.get("abr"),
                    "type": "audio"
                })
            elif f.get("vcodec") != "none" and f.get("acodec") != "none": # Muxed
                 processed_formats.append({
                    "format_id": f.get("format_id"),
                    "ext": f.get("ext"),
                    "resolution": f.get("resolution"),
                    "filesize": f.get("filesize"),
                    "height": f.get("height"),
                    "type": "muxed"
                })
        
        video_data["formats"] = processed_formats
        return video_data

    async def download_video(self, job_id: str, url: str, format_id: str, is_audio_only: bool = False, audio_quality: str = "192"):
        """
        Executes the download using yt-dlp.
        Updates job status via job_store.
        """
        from app.core.jobs import job_store, JobStatus
        import os
        
        job_store.update_job(job_id, status=JobStatus.PROCESSING, progress=0)
        
        # Ensure download directory exists
        output_dir = os.path.join(settings.DOWNLOAD_DIR)
        os.makedirs(output_dir, exist_ok=True)
        
        # Configure unique filename template with Job ID to avoid collisions and allow easy retrieval
        # We use a custom dictionary for outtmpl to treat job_id as a literal part if needed, 
        # but simplest is to inject it into the string.
        outtmpl = os.path.join(output_dir, f'%(title)s [{job_id}].%(ext)s')

        def progress_hook(d):
            if d['status'] == 'downloading':
                try:
                    # Calculate progress safely
                    total = d.get('total_bytes') or d.get('total_bytes_estimate')
                    downloaded = d.get('downloaded_bytes', 0)
                    
                    if total:
                        progress = (downloaded / total) * 100
                    else:
                        # Fallback to parsing string if bytes are missing
                        p = d.get('_percent_str', '0%').replace('%','').strip()
                        # Remove ANSI codes if present
                        import re
                        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
                        p = ansi_escape.sub('', p)
                        progress = float(p)

                    print(f"Job {job_id} Progress: {progress:.1f}%") # Debug log
                    job_store.update_job(job_id, progress=progress, data={"filename": d.get("filename")})
                except Exception as e:
                    print(f"Progress Error: {e}")
            elif d['status'] == 'finished':
                print(f"Job {job_id} Finished download phase")
                # Note: This might be the intermediate file (video only), not the final merged one.
                # We update it anyway, but the endpoint will do a smart search.
                job_store.update_job(job_id, progress=99, data={"filename": d.get("filename")})

        # Construct format string: if video, append +bestaudio to ensure merging
        # If audio only, use bestaudio
        final_format = f"{format_id}+bestaudio/best" if not is_audio_only else "bestaudio/best"

        ydl_opts = {
            'format': final_format,
            'outtmpl': outtmpl,
            'progress_hooks': [progress_hook],
            'ffmpeg_location': settings.ffmpeg_executable,
            'merge_output_format': 'mp4', # Force merge to MP4 container
            'quiet': True,
            'no_warnings': True,
        }
        
        # Add post-processors for audio conversion if needed
        if is_audio_only:
             ydl_opts['postprocessors'] = [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': audio_quality,
            }]
             # Force FFmpeg to use the specific bitrate conversion
             ydl_opts['postprocessor_args'] = [
                 '-b:a', f'{audio_quality}k',
                 '-minrate', f'{audio_quality}k',
                 '-maxrate', f'{audio_quality}k',
                 '-bufsize', f'{audio_quality}k'
             ]

        # For Video downloads (Merging), we also want to ensure high quality audio
        if not is_audio_only:
            # We pass args to the 'Merger' postprocessor to re-encode audio to 320k AAC (or similar)
            # modifying the audio stream while copying video if possible, or re-encoding both if needed.
            # To be safe and ensure quality, we'll suggest encoding audio.
            ydl_opts['postprocessor_args'] = {
                'merger': [
                    '-c:v', 'copy',       # Copy video stream (fast, no quality loss)
                    '-c:a', 'aac',        # Re-encode audio to AAC
                    '-b:a', '320k'        # Force 320k bitrate
                ]
            }

        try:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, lambda: yt_dlp.YoutubeDL(ydl_opts).download([url]))
            job_store.update_job(job_id, status=JobStatus.COMPLETED)
        except Exception as e:
            print(f"Job {job_id} Failed: {e}")
            job_store.update_job(job_id, status=JobStatus.FAILED, error=str(e))

downloader_service = YtDlpService()

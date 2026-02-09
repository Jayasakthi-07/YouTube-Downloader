from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    PROJECT_NAME: str = "YouTube Downloader"
    API_V1_STR: str = "/api/v1"
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Path configuration
    DOWNLOAD_DIR: str = "downloads"
    TEMP_DIR: str = "temp"
    # Dynamic FFmpeg path: check env var first, then system PATH
    FFMPEG_PATH: str = "ffmpeg"

    class Config:
        case_sensitive = True
        env_file = ".env"

    @property
    def ffmpeg_executable(self) -> str:
        import shutil
        import os
        # Priority: Env Var -> System Path -> Default 'ffmpeg'
        custom_path = os.getenv("FFMPEG_PATH")
        if custom_path and os.path.exists(custom_path):
            return custom_path
        
        system_path = shutil.which("ffmpeg")
        if system_path:
            return system_path
            
        return "ffmpeg" # Fallback, hope it's in PATH

@lru_cache()
def get_settings():
    return Settings()

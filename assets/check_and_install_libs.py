import sys
import subprocess
import os

def install_library(library_name):
    """Cài đặt thư viện nếu chưa có."""
    try:
        __import__(library_name)
        print(f"{library_name} is already installed.")
    except ImportError:
        print(f"{library_name} not found. Installing it now...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", library_name])
            print(f"Successfully installed {library_name}.")
        except subprocess.CalledProcessError as e:
            print(f"ERROR: Failed to install {library_name}: {str(e)}", file=sys.stderr)
            sys.exit(1)

def main():
    # Danh sách thư viện cần kiểm tra và cài đặt
    required_libraries = ["yt-dlp"]

    # Kiểm tra và cài đặt từng thư viện
    for lib in required_libraries:
        install_library(lib)

    print("All required libraries are installed.")

if __name__ == "__main__":
    main()
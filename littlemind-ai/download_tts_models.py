import os
import urllib.request
import tarfile

def download_file(url, target_path):
    print(f"Downloading {url} to {target_path}...")
    try:
        urllib.request.urlretrieve(url, target_path)
        print("Success.")
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False

def extract_tar_bz2(file_path, target_dir):
    print(f"Extracting {file_path} to {target_dir}...")
    try:
        with tarfile.open(file_path, "r:bz2") as tar:
            tar.extractall(path=target_dir)
        print("Extraction complete.")
    except Exception as e:
        print(f"Extraction failed: {e}")

def main():
    target_dir = os.path.join("mobile", "flutter_app", "assets", "tts")
    os.makedirs(target_dir, exist_ok=True)
    
    base_url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"
    
    # Pre-packaged Sherpa ONNX models
    models = [
        "vits-piper-en_US-amy-low",
        "vits-piper-hi_IN-priyamvada-medium",
        "vits-piper-hi_IN-rohan-medium"
    ]
    
    for model in models:
        filename = f"{model}.tar.bz2"
        url = f"{base_url}/{filename}"
        tar_path = os.path.join(target_dir, filename)
        
        # Determine if already extracted
        extract_path = os.path.join(target_dir, model)
        if not os.path.exists(extract_path):
            if not os.path.exists(tar_path):
                if download_file(url, tar_path):
                    extract_tar_bz2(tar_path, target_dir)
                    os.remove(tar_path) # Cleanup archive
            else:
                extract_tar_bz2(tar_path, target_dir)
                os.remove(tar_path)
        else:
            print(f"{model} already downloaded and extracted.")

if __name__ == "__main__":
    main()

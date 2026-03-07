import urllib.request
import os

url = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png"
output_path = "assets/images/google_logo.png"

# Ensure directory exists
os.makedirs(os.path.dirname(output_path), exist_ok=True)

try:
    urllib.request.urlretrieve(url, output_path)
    print("Successfully downloaded Google logo to", output_path)
except Exception as e:
    print("Failed to download:", e)

#!/bin/bash

export DIRNAME=${DIRNAME:-"runpod-slim/ComfyUI"}

apt-get update -y
apt-get install zip unzip aria2 -y

download_model() {
    local url="$1" 
    local ws_path="$2" 
    local filename
    filename=$(basename "$ws_path")

    # If present in workspace, skip entirely
    if [ -f "$ws_path" ]; then
        echo "✅ $filename already exists in /workspace; skipping."
        return 0
    fi

    echo "📥 Downloading $filename to local path: $ws_path"
    mkdir -p "$(dirname "$ws_path")"

    if command -v aria2c >/dev/null 2>&1; then
        aria2c --continue=true --max-connection-per-server=8 --split=8 \
               --max-concurrent-downloads=1 --summary-interval=10 \
               --dir="$(dirname "$ws_path")" --out="$(basename "$ws_path")" \
               "$url"
    else
        wget --tries=3 --continue --progress=bar:force:noscroll \
             --content-disposition -O "$ws_path" "$url"
    fi

    echo "✅ Downloaded: $filename (local)."
}

set -euo pipefail

echo "Downloading essential models..."

download_model \
"https://cas-bridge.xethub.hf.co/xet-bridge-us/68fd092451919feb91c16688/f7576bbdaf85f62e0a568bfe382fadc07d8a98795bc3908294b9ca664faf61ba?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=cas%2F20251202%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20251202T191251Z&X-Amz-Expires=3600&X-Amz-Signature=320450654f3f3ab1339611f8d9b958357a6260b54e76cfa43fe93282a5975f60&X-Amz-SignedHeaders=host&X-Xet-Cas-Uid=681db67072c5da00cdd61629&response-content-disposition=inline%3B+filename*%3DUTF-8%27%27smoothMixWan22I2VT2V_t2vHighV20_Q8_0.gguf%3B+filename%3D%22smoothMixWan22I2VT2V_t2vHighV20_Q8_0.gguf%22%3B&x-id=GetObject&Expires=1764706371&Policy=eyJTdGF0ZW1lbnQiOlt7IkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTc2NDcwNjM3MX19LCJSZXNvdXJjZSI6Imh0dHBzOi8vY2FzLWJyaWRnZS54ZXRodWIuaGYuY28veGV0LWJyaWRnZS11cy82OGZkMDkyNDUxOTE5ZmViOTFjMTY2ODgvZjc1NzZiYmRhZjg1ZjYyZTBhNTY4YmZlMzgyZmFkYzA3ZDhhOTg3OTViYzM5MDgyOTRiOWNhNjY0ZmFmNjFiYSoifV19&Signature=s%7EfcmEjpNnPhx0OwdfxGCkJS8qJihKarcmzr3svtUp04XCDp5C9Dq8T9kWbjxbP4wARpZueyoFuE7FY2iln2wMvSLpwL6SpSVJhawiBT5%7ET1CsCYtwFDFvjpYSalzovcVQt%7EtIu1CHOfEfqdFhzhQeGv2I3fwW7GmM5COK7gzuh-9cdX3lDJHZWuF9QDln5psMEeof6OsxptSD1iRKMtwNkhAot7tdv0oFDdXRg3kPEmooMjffXnMyGHf-A9xULFgDiy4F3lANN7-u8s6WL4oCJ3PRVHa%7E6wMLvscqrgmmr-3j29ufWn4vQU42h4tZAFVEQJIcXIlltC9D7Pn0ByEA__&Key-Pair-Id=K2L8F4GPSG1IFC" \
"/workspace/$DIRNAME/models/diffusion_models/smoothMixWan22I2VT2V_t2vHighV20_Q8_0.gguf"

download_model \
"https://cas-bridge.xethub.hf.co/xet-bridge-us/68fd092451919feb91c16688/e45eb1fbcc4d51b50cd6eaf2cbb19e9d5f10feb2cb0f9e520b4bb94d0854551e?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=cas%2F20251202%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20251202T191344Z&X-Amz-Expires=3600&X-Amz-Signature=c6c2f1148af4949c46208338f2ea5014a8b283a38023fa50f0769eb2f23d5744&X-Amz-SignedHeaders=host&X-Xet-Cas-Uid=681db67072c5da00cdd61629&response-content-disposition=attachment%3B+filename*%3DUTF-8%27%27smoothMixWan22I2VT2V_t2vLowV20_Q8_0.gguf%3B+filename%3D%22smoothMixWan22I2VT2V_t2vLowV20_Q8_0.gguf%22%3B&x-id=GetObject&Expires=1764706424&Policy=eyJTdGF0ZW1lbnQiOlt7IkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTc2NDcwNjQyNH19LCJSZXNvdXJjZSI6Imh0dHBzOi8vY2FzLWJyaWRnZS54ZXRodWIuaGYuY28veGV0LWJyaWRnZS11cy82OGZkMDkyNDUxOTE5ZmViOTFjMTY2ODgvZTQ1ZWIxZmJjYzRkNTFiNTBjZDZlYWYyY2JiMTllOWQ1ZjEwZmViMmNiMGY5ZTUyMGI0YmI5NGQwODU0NTUxZSoifV19&Signature=CVAFjciaKI6FOh3DPR3mmKPzxfnSCRdEHbs8eKvZ3OVgSmly5SLLnyfHFoWeL7zTC0o50czIsWdOU8Wno1cDREw8m4p8OM1%7E1yswsWQ78jjbJQaqYTdps24hDZkx55JejU0kmpY2e6ssdJ2rmaCLil9ogp6D8WA0ljqNsdDZ0rydI9BexFcsvh6CTa6lVL4kecyOsLGCifiHj%7E%7E3QriwHCsUXmmtAkaomepdyARNBQkHUeP-LgcN7yKEuPk4W80n4zqSIhJXdHfmRZB722F%7EyYmVOt25btgktOz57aKEgx3GZVLUyl98HiMyHURchnFSt39ddHlEmjgZGAF%7EkR0PYQ__&Key-Pair-Id=K2L8F4GPSG1IFC" \
"/workspace/$DIRNAME/models/diffusion_models/smoothMixWan22I2VT2V_t2vLowV20_Q8_0.gguf"

download_model \
"https://huggingface.co/KeyOpening8063587/SMOOTHXXX/resolve/main/SmoothXXXAnimation_High.safetensors" \
"/workspace/$DIRNAME/models/loras/SmoothXXXAnimation_High.safetensors"

download_model \
"https://huggingface.co/KeyOpening8063587/SMOOTHXXX/resolve/main/SmoothXXXAnimation_Low.safetensors" \
"/workspace/$DIRNAME/models/loras/SmoothXXXAnimation_Low.safetensors"

download_model \
"https://huggingface.co/ratoenien/umt5_xxl_fp8_e4m3fn_scaled/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
"/workspace/$DIRNAME/models/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

download_model \
"https://huggingface.co/Osrivers/wan_2.1_vae.safetensors/resolve/main/wan_2.1_vae.safetensors" \
"/workspace/$DIRNAME/models/vae/wan_2.1_vae.safetensors"

# Wait for all processes
wait

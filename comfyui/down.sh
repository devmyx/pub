#!/bin/bash

# bash <(wget -qO- https://raw.githubusercontent.com/devmyx/pub/refs/heads/main/comfyui/down.sh)

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
"https://huggingface.co/BigDannyPt/WAN-2.2-SmoothMix-GGUF/resolve/main/v2.0/High/smoothMixWan22I2VT2V_t2vHighV20_Q6_K.gguf?not-for-all-audiences=true" \
"/workspace/$DIRNAME/models/diffusion_models/smoothMixWan22I2VT2V_t2vHighV20_Q8_0.gguf"

download_model \
"https://huggingface.co/BigDannyPt/WAN-2.2-SmoothMix-GGUF/resolve/main/v2.0/Low/smoothMixWan22I2VT2V_t2vLowV20_Q6_K.gguf?not-for-all-audiences=true" \
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

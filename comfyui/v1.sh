#!/bin/bash

# bash <(wget -qO- https://raw.githubusercontent.com/...comfyui.sh)

apt-get update -y
apt-get install zip unzip aria2 -y

export USE_SAGE_ATTENTION=${USE_SAGE_ATTENTION:-"false"}
export USE_VENV=${USE_VENV:-"true"}

export DIRNAME=${DIRNAME:-"comfyui-v1"}
ARGS=("$@" --listen 0.0.0.0 --port 8188 --disable-xformers)

export PYTHONUNBUFFERED=1

TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

export TORCH_FORCE_WEIGHTS_ONLY_LOAD=1

# Set strict error handling
set -e

# Function to reset GPU state
reset_gpu() {
    echo "Resetting GPU state..."
    nvidia-smi --gpu-reset 2>/dev/null || true
    sleep 2
}

# Install uv if not already installed
install_uv() {
    if ! command -v uv &>/dev/null; then
        echo "Installing uv package installer..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "uv already installed, skipping..."
    fi
}

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

# Ensure CUDA environment is properly set
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_LAUNCH_BLOCKING=1

# Create necessary directories
# mkdir -p /workspace/logs
# mkdir -p /workspace/$DIRNAME

# install_uv

# Create dirs and download ComfyUI if it doesn't exist
if [ ! -e "/workspace/$DIRNAME/main.py" ]; then
    echo "ComfyUI not found or incomplete, installing..."

    # Remove incomplete directory if it exists
    rm -rf /workspace/$DIRNAME

    # Create workspace and log directories
    mkdir -p /workspace/logs

    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI /workspace/$DIRNAME

    # Install dependencies
    cd /workspace/$DIRNAME

    if [ "$USE_VENV" = "true" ]; then
        python -m venv venv
        source venv/bin/activate
    fi

    pip install uv

    # echo "Installing PyTorch dependencies..."
    # uv pip install --no-cache torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128
    echo "Installing ComfyUI requirements..."
    uv pip install --no-cache -r requirements.txt

    if [ "$USE_SAGE_ATTENTION" = "true" ]; then
        # Install SageAttention 2.2.0 from prebuilt wheel (no compilation needed)
        echo "Installing SageAttention 2.2.0 from prebuilt wheel..."
        uv pip install https://huggingface.co/Kijai/PrecompiledWheels/resolve/main/sageattention-2.2.0-cp312-cp312-linux_x86_64.whl
        echo "SageAttention 2.2.0 installation complete"
    
        # Install SageAttention 3 from prebuilt wheel (no compilation needed)
        echo "Installing SageAttention 3 from prebuilt wheel..."
        uv pip install https://huggingface.co/vjump21848/sageattention-pre-compiled-wheel/resolve/main/sageattn3-1.0.0%2Bcu128-cp312-cp312-linux_x86_64.whl
        echo "SageAttention 3 installation complete"
    fi
    
    cd /workspace/$DIRNAME

    # Create model directories
    mkdir -p /workspace/$DIRNAME/models/{checkpoints,vae,unet,diffusion_models,text_encoders,loras,upscale_models,clip,controlnet,clip_vision,ipadapter,style_models}
    mkdir -p /workspace/$DIRNAME/custom_nodes
    mkdir -p /workspace/$DIRNAME/input
    mkdir -p /workspace/$DIRNAME/output

    # Clone custom nodes
    mkdir -p /workspace/$DIRNAME/custom_nodes
    cd /workspace/$DIRNAME/custom_nodes

    echo "Cloning custom nodes..."
    git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager.git
    git clone --depth=1 https://github.com/rgthree/rgthree-comfy.git
    git clone --depth=1 https://github.com/crystian/ComfyUI-Crystools.git
    git clone --depth=1 https://github.com/liusida/ComfyUI-Login.git

    # Install custom nodes requirements
    echo "Installing custom node requirements..."
    find . -name "requirements.txt" -exec uv pip install --no-cache -r {} \;

    mkdir -p /workspace/$DIRNAME/user/default/ComfyUI-Manager
    wget https://gist.githubusercontent.com/vjumpkung/b2993de3524b786673552f7de7490b08/raw/b7ae0b4fe0dad5c930ee290f600202f5a6c70fa8/uv_enabled_config.ini -O /workspace/$DIRNAME/user/default/ComfyUI-Manager/config.ini

    cd /workspace

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
    "/workspace/$DIRNAME/models/loras/SmoothXXXAnimation_High.safetensors"

    # download_model \
    # "civita?token={api_key}" \
    # "/workspace/$DIRNAME/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors"

else
    echo "ComfyUI already exists, skipping clone"

    if [ "$USE_VENV" = "true" ]; then
        source venv/bin/activate
    fi

fi

# Initialize GPU - Do this before downloading models to ensure GPU is ready
echo "Initializing GPU..."
reset_gpu

# Start services with proper sequencing
echo "Starting services..."

# Start Jupyter with GPU isolation
# jupyter lab --allow-root --no-browser --ip=0.0.0.0 --port=8888 --NotebookApp.token="Mobiles" --NotebookApp.password="Mobiles" --notebook-dir=/ &

# Give other services time to initialize
sleep 5

# Start ComfyUI with full GPU access
cd /workspace/$DIRNAME

# Clear any existing CUDA cache
python -c "import torch; torch.cuda.empty_cache()" || true
# Add a clear marker in the log file
echo "===================================================================="
echo "============ ComfyUI STARTING $(date) ============"
echo "===================================================================="
# Start ComfyUI with proper logging
echo "Starting ComfyUI on port 8188..."
# Use unbuffer to ensure output is line-buffered for better real-time logging
if [ "$USE_SAGE_ATTENTION" = "true" ]; then
    python main.py --use-sage-attention "${ARGS[@]}" &
else
    python main.py "${ARGS[@]}" &
fi
# Record the PID of the ComfyUI process
COMFY_PID=$!
echo "ComfyUI started with PID: $COMFY_PID"

# Wait for all processes
wait

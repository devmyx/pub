#!/bin/bash

# bash <(wget -qO- https://raw.githubusercontent.com/...comfyui.sh)

apt-get update -y
apt-get install zip unzip aria2 -y

export USE_SAGE_ATTENTION=${USE_SAGE_ATTENTION:-"true"}
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

install_uv

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

    # echo "Installing PyTorch dependencies..."
    # uv pip install --no-cache torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128
    echo "Installing ComfyUI requirements..."
    uv pip install --no-cache -r requirements.txt

    # Install SageAttention 2.2.0 from prebuilt wheel (no compilation needed)
    echo "Installing SageAttention 2.2.0 from prebuilt wheel..."
    uv pip install https://huggingface.co/Kijai/PrecompiledWheels/resolve/main/sageattention-2.2.0-cp312-cp312-linux_x86_64.whl
    echo "SageAttention 2.2.0 installation complete"

    # Install SageAttention 3 from prebuilt wheel (no compilation needed)
    echo "Installing SageAttention 3 from prebuilt wheel..."
    uv pip install https://huggingface.co/vjump21848/sageattention-pre-compiled-wheel/resolve/main/sageattn3-1.0.0%2Bcu128-cp312-cp312-linux_x86_64.whl
    echo "SageAttention 3 installation complete"
    
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

    # Install custom nodes requirements
    echo "Installing custom node requirements..."
    find . -name "requirements.txt" -exec uv pip install --no-cache -r {} \;

    mkdir -p /workspace/$DIRNAME/user/default/ComfyUI-Manager
    wget https://gist.githubusercontent.com/vjumpkung/b2993de3524b786673552f7de7490b08/raw/b7ae0b4fe0dad5c930ee290f600202f5a6c70fa8/uv_enabled_config.ini -O /workspace/$DIRNAME/user/default/ComfyUI-Manager/config.ini

    cd /workspace

    set -euo pipefail

    echo "Downloading essential models..."

    download_model \
    "https://huggingface.co/BigDannyPt/WAN-2.2-SmoothMix-GGUF/resolve/main/v2.0/High/smoothMixWan22I2VT2V_t2vHighV20_Q8_0.gguf" \
    "/workspace/$DIRNAME/models/diffusion_models/smoothMixWan22I2VT2V_t2vHighV20_Q8_0.gguf"

    download_model \
    "https://huggingface.co/BigDannyPt/WAN-2.2-SmoothMix-GGUF/resolve/main/v2.0/Low/smoothMixWan22I2VT2V_t2vLowV20_Q8_0.gguf" \
    "/workspace/$DIRNAME/models/diffusion_models/smoothMixWan22I2VT2V_t2vLowV20_Q8_0.gguf"

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

#!/bin/bash

# bash <(wget -qO- https://raw.githubusercontent.com/devmyx/pub/refs/heads/main/comfyui/update.v2.sh)

# bash -c "/workspace/update.sh"
# chmod +x ./update.sh

set -e  # Exit the script if any statement returns a non-true return value

COMFYUI_DIR="/workspace/runpod-slim/ComfyUI"
VENV_DIR="$COMFYUI_DIR/.venv"

echo "START"

cd $COMFYUI_DIR

source $VENV_DIR/bin/activate

pip install uv

uv pip install https://huggingface.co/Kijai/PrecompiledWheels/resolve/main/sageattention-2.2.0-cp312-cp312-linux_x86_64.whl
uv pip install https://huggingface.co/vjump21848/sageattention-pre-compiled-wheel/resolve/main/sageattn3-1.0.0%2Bcu128-cp312-cp312-linux_x86_64.whl

cd "$COMFYUI_DIR/custom_nodes"

git clone --depth=1 https://github.com/rgthree/rgthree-comfy.git
git clone --depth=1 https://github.com/crystian/ComfyUI-Crystools.git
git clone --depth=1 https://github.com/liusida/ComfyUI-Login.git

echo "Installing custom node requirements..."
find . -name "requirements.txt" -exec uv pip install --no-cache -r {} \;

cd $COMFYUI_DIR

# /workspace/runpod-slim/comfyui_args.txt
# --use-sage-attention
# --disable-xformers

echo "END"

# Wait for all processes
wait

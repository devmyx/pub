#!/bin/bash

SAGE_BUILD_DIR="/workspace/.sageattention_builds"

# pip install --upgrade pip setuptools wheel packaging ninja opencv-python -q --disable-pip-version-check

echo "⚡ Building SageAttention 2.2.0 from source (all architectures)..."

# Set all supported architectures for broad GPU compatibility
export TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0 12.0 12.8"

GPU_BUILD_DIR="$SAGE_BUILD_DIR/all_archs"
mkdir -p "$GPU_BUILD_DIR"

if [ ! -f "$GPU_BUILD_DIR/.installed" ]; then
    echo "⚡ Cloning and building SageAttention..."
    python -m pip install --upgrade pip setuptools wheel -q --disable-pip-version-check

    cd "$GPU_BUILD_DIR"
    git clone --depth 1 https://github.com/woct0rdho/SageAttention.git .
    python -m pip install . --no-build-isolation --force-reinstall -q
    cd "$INSTALL_DIR"

    touch "$GPU_BUILD_DIR/.installed"
    echo "✨ SageAttention built for all architectures."
else
    echo "✨ SageAttention already built for all architectures, skipping rebuild."
fi
echo "------------------------------------------------------------"

# python3 main.py --preview-method auto --use-sage-attention --listen 0.0.0.0 --port 8188

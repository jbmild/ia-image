#!/bin/bash
# Script alternativo en bash para descargar modelos
# Requiere: huggingface-cli instalado (pip install huggingface_hub[cli])

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}🎬 Descargador de Modelos LTX-Video${NC}"
echo -e "${BLUE}============================================================${NC}\n"

# Verificar si huggingface-cli está instalado
if ! command -v huggingface-cli &> /dev/null; then
    echo -e "${RED}❌ Error: huggingface-cli no está instalado${NC}"
    echo -e "${YELLOW}   Instala con: pip install huggingface_hub[cli]${NC}"
    echo -e "${YELLOW}   O usa el script Python: python download_models.py${NC}"
    exit 1
fi

# Directorios
BASE_DIR="./comfyui_storage/models"
DIFFUSION_DIR="$BASE_DIR/diffusion_models"
TEXT_ENCODER_DIR="$BASE_DIR/text_encoders"
VAE_DIR="$BASE_DIR/vae"
CUSTOM_NODES_DIR="./comfyui_storage/custom_nodes"

# Crear directorios
mkdir -p "$DIFFUSION_DIR" "$TEXT_ENCODER_DIR" "$VAE_DIR" "$CUSTOM_NODES_DIR"
echo -e "${GREEN}✓${NC} Directorios creados/verificados\n"

# 1. Descargar modelo LTX-Video
echo -e "${BLUE}1. Modelo Principal LTX-Video${NC}"
echo "   Repositorio: Lightricks/LTX-Video"
if [ -d "$DIFFUSION_DIR/Lightricks--LTX-Video" ] || [ -f "$DIFFUSION_DIR"/*.safetensors ]; then
    echo -e "${GREEN}✓${NC} Modelo ya existe, omitiendo..."
else
    echo -e "${BLUE}⏳${NC} Descargando..."
    huggingface-cli download Lightricks/LTX-Video \
        --local-dir "$DIFFUSION_DIR" \
        --local-dir-use-symlinks False \
        || echo -e "${YELLOW}⚠${NC} Error descargando. Intenta manualmente desde: https://huggingface.co/Lightricks/LTX-Video"
fi

# 2. Descargar T5-XXL
echo -e "\n${BLUE}2. Text Encoder T5-XXL${NC}"
if [ -d "$TEXT_ENCODER_DIR/google--t5-v1_1-xxl" ] || [ -f "$TEXT_ENCODER_DIR"/*.safetensors ] || [ -f "$TEXT_ENCODER_DIR"/*.bin ]; then
    echo -e "${GREEN}✓${NC} T5-XXL ya existe, omitiendo..."
else
    echo -e "${BLUE}⏳${NC} Descargando..."
    huggingface-cli download google/t5-v1_1-xxl \
        --local-dir "$TEXT_ENCODER_DIR" \
        --local-dir-use-symlinks False \
        || echo -e "${YELLOW}⚠${NC} Error descargando. Intenta manualmente desde: https://huggingface.co/google/t5-v1_1-xxl"
fi

# 3. Descargar VAE (opcional)
echo -e "\n${BLUE}3. VAE (Opcional)${NC}"
if [ -f "$VAE_DIR"/*.safetensors ]; then
    echo -e "${GREEN}✓${NC} VAE ya existe, omitiendo..."
else
    echo -e "${BLUE}⏳${NC} Descargando..."
    huggingface-cli download stabilityai/sd-vae-ft-mse \
        --local-dir "$VAE_DIR" \
        --local-dir-use-symlinks False \
        || echo -e "${YELLOW}⚠${NC} VAE opcional, puede no ser necesario"
fi

# 4. Instalar nodos personalizados
echo -e "\n${BLUE}4. Nodos Personalizados ComfyUI-LTXVideo${NC}"
if [ -d "$CUSTOM_NODES_DIR/ComfyUI-LTXVideo" ]; then
    echo -e "${GREEN}✓${NC} ComfyUI-LTXVideo ya está instalado"
else
    if command -v git &> /dev/null; then
        echo -e "${BLUE}⏳${NC} Clonando repositorio..."
        cd "$CUSTOM_NODES_DIR"
        git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git || echo -e "${RED}✗${NC} Error clonando repositorio"
        cd - > /dev/null
    else
        echo -e "${RED}✗${NC} Git no está instalado"
        echo -e "${YELLOW}   Instala con: sudo apt-get install git${NC}"
    fi
fi

# Resumen
echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN}✓ Descarga completada${NC}"
echo -e "${BLUE}============================================================${NC}\n"

TOTAL_SIZE=$(du -sh "$BASE_DIR" 2>/dev/null | cut -f1 || echo "N/A")
echo -e "💾 Tamaño total: ${TOTAL_SIZE}"
echo -e "📁 Ubicación: $(realpath "$BASE_DIR")\n"

echo -e "${GREEN}✅ Modelos listos para usar${NC}"
echo -e "\n${BLUE}Próximo paso:${NC} docker compose up -d"

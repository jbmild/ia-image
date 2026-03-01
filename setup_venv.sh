#!/bin/bash
# Script rápido para crear y configurar el entorno virtual

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

VENV_DIR="./venv"

if [ ! -d "$VENV_DIR" ]; then
    echo -e "${BLUE}Creando entorno virtual...${NC}"
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}✓${NC} Entorno virtual creado"
else
    echo -e "${GREEN}✓${NC} Entorno virtual ya existe"
fi

echo -e "\n${BLUE}Activando entorno virtual...${NC}"
source "$VENV_DIR/bin/activate"

echo -e "${BLUE}Actualizando pip...${NC}"
pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    echo -e "\n${BLUE}Instalando dependencias...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✓${NC} Dependencias instaladas"
else
    echo -e "\n${YELLOW}⚠${NC} requirements.txt no encontrado"
    echo -e "${BLUE}Instalando dependencias básicas...${NC}"
    pip install huggingface_hub tqdm
fi

echo -e "\n${GREEN}✅ Entorno virtual configurado${NC}"
echo -e "\n${BLUE}Para usar el entorno virtual:${NC}"
echo -e "  ${YELLOW}source venv/bin/activate${NC}"
echo -e "\n${BLUE}Para desactivar:${NC}"
echo -e "  ${YELLOW}deactivate${NC}"

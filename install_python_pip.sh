#!/bin/bash
# Script para instalar Python y pip en WSL2 (Ubuntu)

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}🐍 Instalador de Python y pip para WSL2${NC}"
echo -e "${BLUE}============================================================${NC}\n"

# Verificar si ya está instalado
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} Python3 ya está instalado: $PYTHON_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Python3 no encontrado, instalando..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
fi

# Verificar pip
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    echo -e "${GREEN}✓${NC} pip3 ya está instalado: $PIP_VERSION"
else
    echo -e "${YELLOW}⚠${NC} pip3 no encontrado, instalando..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
fi

# Actualizar pip a la última versión
echo -e "\n${BLUE}Actualizando pip a la última versión...${NC}"
python3 -m pip install --upgrade pip --user

# Verificar instalación
echo -e "\n${BLUE}=== Verificación ===${NC}\n"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} Python: $PYTHON_VERSION"
    echo -e "   Ubicación: $(which python3)"
else
    echo -e "${RED}✗${NC} Python3 no está instalado correctamente"
    exit 1
fi

if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    echo -e "${GREEN}✓${NC} pip: $PIP_VERSION"
    echo -e "   Ubicación: $(which pip3)"
else
    echo -e "${RED}✗${NC} pip3 no está instalado correctamente"
    exit 1
fi

# Crear alias para pip (opcional)
if ! command -v pip &> /dev/null; then
    echo -e "\n${BLUE}Creando alias 'pip' para 'pip3'...${NC}"
    echo "alias pip='pip3'" >> ~/.bashrc
    echo -e "${GREEN}✓${NC} Alias creado. Ejecuta 'source ~/.bashrc' o reinicia la terminal"
fi

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ Python y pip instalados correctamente${NC}"
echo -e "${BLUE}============================================================${NC}\n"

echo -e "${BLUE}Próximos pasos:${NC}"
echo "  1. Instalar dependencias del proyecto:"
echo "     ${YELLOW}pip3 install -r requirements.txt${NC}"
echo ""
echo "  2. O instalar manualmente:"
echo "     ${YELLOW}pip3 install huggingface_hub tqdm${NC}"
echo ""
echo "  3. Verificar instalación:"
echo "     ${YELLOW}./check_dependencies.sh${NC}"

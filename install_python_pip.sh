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

# Instalar python3-full (necesario para crear entornos virtuales)
if ! dpkg -l | grep -q python3-full; then
    echo -e "\n${BLUE}Instalando python3-full (necesario para entornos virtuales)...${NC}"
    sudo apt-get install -y python3-full python3-venv
fi

# Crear entorno virtual si no existe
VENV_DIR="./venv"
if [ ! -d "$VENV_DIR" ]; then
    echo -e "\n${BLUE}Creando entorno virtual en ./venv...${NC}"
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}✓${NC} Entorno virtual creado"
else
    echo -e "\n${GREEN}✓${NC} Entorno virtual ya existe"
fi

# Activar entorno virtual y actualizar pip
echo -e "\n${BLUE}Actualizando pip en el entorno virtual...${NC}"
source "$VENV_DIR/bin/activate"
python -m pip install --upgrade pip

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

# Instalar dependencias del proyecto en el entorno virtual
if [ -f "requirements.txt" ]; then
    echo -e "\n${BLUE}Instalando dependencias del proyecto...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✓${NC} Dependencias instaladas"
else
    echo -e "\n${YELLOW}⚠${NC} requirements.txt no encontrado, instalando dependencias básicas..."
    pip install huggingface_hub tqdm
fi

# Desactivar entorno virtual
deactivate

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ Python, pip y dependencias instalados correctamente${NC}"
echo -e "${BLUE}============================================================${NC}\n"

echo -e "${BLUE}📝 IMPORTANTE: Usa el entorno virtual para ejecutar scripts${NC}\n"

echo -e "${BLUE}Próximos pasos:${NC}"
echo "  1. Activar el entorno virtual antes de usar los scripts:"
echo "     ${YELLOW}source venv/bin/activate${NC}"
echo ""
echo "  2. Ejecutar el script de descarga de modelos:"
echo "     ${YELLOW}python download_models.py${NC}"
echo ""
echo "  3. Para desactivar el entorno virtual:"
echo "     ${YELLOW}deactivate${NC}"
echo ""
echo -e "${YELLOW}💡 Tip:${NC} El entorno virtual está en ./venv/"
echo -e "   Puedes activarlo automáticamente añadiendo a ~/.bashrc:"
echo -e "   ${YELLOW}echo 'cd $(pwd) && source venv/bin/activate' >> ~/.bashrc${NC}"

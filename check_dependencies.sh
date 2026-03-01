#!/bin/bash
# Script para verificar que todas las dependencias necesarias están instaladas

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}🔍 Verificación de Dependencias${NC}"
echo -e "${BLUE}============================================================${NC}\n"

ERRORS=0
WARNINGS=0

# Función para verificar comando
check_command() {
    local cmd=$1
    local name=$2
    local required=${3:-true}
    
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} $name: $version"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $name: NO INSTALADO (requerido)"
            ((ERRORS++))
        else
            echo -e "${YELLOW}⚠${NC} $name: NO INSTALADO (opcional)"
            ((WARNINGS++))
        fi
        return 1
    fi
}

# Función para verificar módulo de Python
check_python_module() {
    local module=$1
    local name=$2
    local required=${3:-true}
    
    if python3 -c "import $module" 2>/dev/null; then
        local version=$(python3 -c "import $module; print($module.__version__)" 2>/dev/null || echo "instalado")
        echo -e "${GREEN}✓${NC} Python: $name ($version)"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} Python: $name NO INSTALADO (requerido para download_models.py)"
            echo -e "   ${YELLOW}→${NC} Instala con: pip install $module"
            ((ERRORS++))
        else
            echo -e "${YELLOW}⚠${NC} Python: $name NO INSTALADO (opcional)"
            ((WARNINGS++))
        fi
        return 1
    fi
}

echo -e "${BLUE}=== Software del Sistema ===${NC}\n"

# Verificar Python
check_command "python3" "Python 3" true
PYTHON_OK=$?

# Verificar pip
check_command "pip" "pip" true
PIP_OK=$?

# Verificar Docker
check_command "docker" "Docker" true
DOCKER_OK=$?

# Verificar Docker Compose
if command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        VERSION=$(docker compose version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} Docker Compose: $VERSION"
    else
        echo -e "${RED}✗${NC} Docker Compose: NO INSTALADO (requerido)"
        echo -e "   ${YELLOW}→${NC} Docker Compose v2 debería venir con Docker Desktop"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} Docker Compose: NO VERIFICABLE (Docker no instalado)"
fi

# Verificar git
check_command "git" "Git" false
GIT_OK=$?

# Verificar GPU (nvidia-smi)
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | head -n 1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} NVIDIA GPU: $GPU_INFO"
    else
        echo -e "${YELLOW}⚠${NC} NVIDIA GPU: No accesible desde WSL2"
        echo -e "   ${YELLOW}→${NC} Asegúrate de tener drivers NVIDIA instalados en Windows"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} NVIDIA GPU: nvidia-smi no disponible"
    echo -e "   ${YELLOW}→${NC} Instala drivers NVIDIA en Windows"
    ((WARNINGS++))
fi

echo -e "\n${BLUE}=== Dependencias Python (para download_models.py) ===${NC}\n"

if [ $PYTHON_OK -eq 0 ] && [ $PIP_OK -eq 0 ]; then
    check_python_module "huggingface_hub" "huggingface_hub" true
    check_python_module "tqdm" "tqdm" true
    
    # Verificar huggingface-cli (opcional, para script bash)
    if command -v huggingface-cli &> /dev/null; then
        VERSION=$(huggingface-cli --version 2>&1 | head -n 1 || echo "instalado")
        echo -e "${GREEN}✓${NC} huggingface-cli: $VERSION"
    else
        echo -e "${YELLOW}⚠${NC} huggingface-cli: NO INSTALADO (opcional, para download_models.sh)"
        echo -e "   ${YELLOW}→${NC} Instala con: pip install huggingface_hub[cli]"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}✗${NC} No se pueden verificar módulos Python (Python o pip no instalados)"
    ((ERRORS++))
fi

echo -e "\n${BLUE}=== Verificación de Archivos del Proyecto ===${NC}\n"

# Verificar archivos importantes
if [ -f "docker-compose.yml" ]; then
    echo -e "${GREEN}✓${NC} docker-compose.yml existe"
else
    echo -e "${RED}✗${NC} docker-compose.yml NO ENCONTRADO"
    ((ERRORS++))
fi

if [ -f "download_models.py" ]; then
    echo -e "${GREEN}✓${NC} download_models.py existe"
else
    echo -e "${YELLOW}⚠${NC} download_models.py NO ENCONTRADO"
    ((WARNINGS++))
fi

if [ -f "requirements.txt" ]; then
    echo -e "${GREEN}✓${NC} requirements.txt existe"
else
    echo -e "${YELLOW}⚠${NC} requirements.txt NO ENCONTRADO"
    ((WARNINGS++))
fi

# Verificar estructura de carpetas
if [ -d "comfyui_storage" ]; then
    echo -e "${GREEN}✓${NC} Directorio comfyui_storage existe"
else
    echo -e "${YELLOW}⚠${NC} Directorio comfyui_storage NO EXISTE (se creará automáticamente)"
    ((WARNINGS++))
fi

echo -e "\n${BLUE}============================================================${NC}"

# Resumen
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las dependencias están instaladas${NC}"
    echo -e "\n${BLUE}Próximos pasos:${NC}"
    echo "  1. Configura WSL2 RAM (ver README)"
    echo "  2. Ejecuta: python download_models.py"
    echo "  3. Ejecuta: docker compose up -d"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} Dependencias principales OK, pero hay $WARNINGS advertencia(s)"
    echo -e "\n${BLUE}Próximos pasos:${NC}"
    echo "  1. Revisa las advertencias arriba"
    echo "  2. Instala dependencias opcionales si las necesitas"
    echo "  3. Ejecuta: pip install -r requirements.txt"
    exit 0
else
    echo -e "${RED}❌ Faltan $ERRORS dependencia(s) requerida(s)${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}   Y $WARNINGS advertencia(s)${NC}"
    fi
    echo -e "\n${BLUE}Acciones recomendadas:${NC}"
    echo "  1. Instala las dependencias faltantes (marcadas con ✗)"
    echo "  2. Para Python: pip install -r requirements.txt"
    echo "  3. Para Docker: Instala Docker Desktop desde docker.com"
    echo "  4. Para GPU: Instala drivers NVIDIA en Windows"
    exit 1
fi

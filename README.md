# LTX-Video con ComfyUI

Configuración de LTX-Video usando ComfyUI en Docker para generar videos a partir de texto e imágenes.

## Requisitos Previos

### Software del Sistema
- Windows con WSL2 instalado
- Docker Desktop con soporte WSL2 habilitado
- Docker Compose v2
- NVIDIA GPU (4060 Ti 8GB) con drivers CUDA instalados en Windows

### Dependencias para Scripts de Descarga

#### Instalar Python y pip en WSL2

**⚠️ IMPORTANTE:** Ubuntu 24.04 usa entornos gestionados externamente. Debes usar un **entorno virtual** para instalar paquetes Python.

**Opción 1: Script automático (Recomendado)**
```bash
# Este script crea un entorno virtual e instala todo automáticamente
./install_python_pip.sh
```

**Opción 2: Crear entorno virtual manualmente**
```bash
# 1. Instalar Python y herramientas necesarias
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv python3-full

# 2. Crear entorno virtual
python3 -m venv venv

# 3. Activar el entorno virtual
source venv/bin/activate

# 4. Instalar dependencias
pip install -r requirements.txt
```

**Opción 3: Script rápido de entorno virtual**
```bash
./setup_venv.sh
```

#### Usar el entorno virtual

**Cada vez que quieras usar los scripts Python, activa el entorno virtual:**
```bash
# Activar entorno virtual
source venv/bin/activate

# Ahora puedes usar pip y python normalmente
pip install huggingface_hub tqdm
python download_models.py

# Desactivar cuando termines
deactivate
```

**Nota:** El entorno virtual se crea en `./venv/` y contiene todas las dependencias del proyecto.

**Para usar `download_models.sh`:**
```bash
pip3 install huggingface_hub[cli]
# También necesitas git instalado:
sudo apt-get install git  # En WSL2
```

**Verificar dependencias automáticamente:**
```bash
# Ejecutar script de verificación
./check_dependencies.sh
```

**O verificar manualmente:**
```bash
# Verificar Python y pip
python3 --version
pip --version

# Verificar Docker
docker --version
docker compose version

# Verificar GPU en WSL2
nvidia-smi

# Verificar git (para nodos personalizados)
git --version
```

## Configuración Inicial

### 1. Configurar RAM en WSL2 (CRÍTICO)

Los modelos se cargan primero en la RAM del sistema antes de pasar a la GPU. El límite por defecto de WSL2 causará errores de Out of Memory.

**En Windows:**

1. Abre el Explorador de Archivos y navega a `%USERPROFILE%` (tu carpeta de usuario, ej. `C:\Users\Joni`)
2. Crea o edita un archivo llamado `.wslconfig` (sin extensión)
3. Añade estas líneas:

```ini
[wsl2]
memory=24GB
swap=8GB
```

4. Abre PowerShell como administrador y ejecuta:
   ```powershell
   wsl --shutdown
   ```

5. Espera unos segundos y vuelve a abrir WSL2

> **Nota:** Se incluye un archivo `.wslconfig.example` en este proyecto como referencia. Cópialo a `%USERPROFILE%\.wslconfig` en Windows.

### 2. Levantar el Contenedor Docker

Desde la terminal de WSL2, en el directorio del proyecto:

```bash
docker compose up -d
```

Esto descargará la imagen de ComfyUI y creará las carpetas necesarias en `./comfyui_storage`.

Para ver los logs:
```bash
docker compose logs -f
```

Para detener el contenedor:
```bash
docker compose down
```

### 3. Descargar los Modelos

LTX-Video requiere dos componentes principales:

#### Opción A: Descarga Automática (Recomendado)

Se incluyen scripts para descargar automáticamente todos los modelos necesarios:

**Usando Python (Recomendado):**
```bash
# 1. Activar entorno virtual (si no está activo)
source venv/bin/activate

# 2. Ejecutar script de descarga
python download_models.py

# 3. Desactivar entorno virtual cuando termines
deactivate
```

**Usando Bash:**
```bash
# Instalar huggingface-cli si no lo tienes
pip install huggingface_hub[cli]

# Ejecutar script
./download_models.sh
```

Los scripts descargarán automáticamente:
- Modelo principal LTX-Video desde `Lightricks/LTX-Video`
- Text Encoder T5-XXL desde `google/t5-v1_1-xxl`
- VAE (opcional) desde `stabilityai/sd-vae-ft-mse`
- Nodos personalizados ComfyUI-LTXVideo

#### Opción B: Descarga Manual

Si prefieres descargar manualmente:

**Modelo Principal (LTX-Video):**
1. Ve al repositorio oficial en Hugging Face: [Lightricks/LTX-Video](https://huggingface.co/Lightricks/LTX-Video)
2. Descarga el archivo `.safetensors` (versión optimizada o checkpoint unificado)
3. Guárdalo en: `./comfyui_storage/models/diffusion_models/`

**Text Encoder (T5-XXL):**
Para una GPU de 8GB, se recomienda usar una versión cuantizada en FP8 del T5-v1.1-xxl:
1. Busca el modelo T5-XXL cuantizado en Hugging Face: [google/t5-v1_1-xxl](https://huggingface.co/google/t5-v1_1-xxl)
2. Descarga los archivos del modelo
3. Guárdalos en: `./comfyui_storage/models/text_encoders/`

> **Nota:** Los modelos pueden ser muy grandes (30-40GB en total). Asegúrate de tener suficiente espacio en disco.

## Uso

### Acceder a la Interfaz

Una vez que el contenedor esté corriendo y los modelos estén descargados:

1. Abre tu navegador en Windows
2. Ve a: `http://localhost:8188`

### Flujo de Trabajo

ComfyUI funciona con una interfaz basada en nodos. Para LTX-Video:

1. **Cargar un workflow existente:**
   - La comunidad de ComfyUI tiene plantillas pre-armadas para "Texto + Imagen a Video"
   - Busca workflows de LTX-Video en [ComfyUI Workflows](https://github.com/comfyanonymous/ComfyUI_examples)
   - Arrastra y suelta el archivo `.json` o `.png` en la interfaz

2. **Generar video:**
   - Configura los parámetros (texto, imagen de entrada, duración, etc.)
   - Haz clic en "Queue Prompt"
   - El video generado se guardará en `./comfyui_storage/output/`

## Estructura de Carpetas

```
casamiento-daiana/
├── docker-compose.yml
├── README.md
├── .wslconfig.example
├── requirements.txt
├── download_models.py          # Script Python para descargar modelos
├── download_models.sh           # Script Bash alternativo
├── check_dependencies.sh        # Script para verificar dependencias
├── install_python_pip.sh        # Script para instalar Python y pip en WSL2
├── setup_venv.sh                # Script rápido para crear entorno virtual
├── venv/                        # Entorno virtual (se crea al ejecutar setup)
└── comfyui_storage/
    ├── models/
    │   ├── diffusion_models/    # Modelo LTX-Video aquí
    │   ├── text_encoders/       # T5-XXL aquí
    │   └── vae/                 # VAE (opcional)
    ├── output/                  # Videos generados
    └── custom_nodes/            # Nodos personalizados (ComfyUI-LTXVideo)
```

## Solución de Problemas

### Error: Out of Memory
- Verifica que `.wslconfig` esté configurado correctamente
- Asegúrate de haber reiniciado WSL2 después de cambiar `.wslconfig`
- Considera reducir el tamaño del batch o la resolución del video

### Error: GPU no detectada
- Verifica que Docker Desktop tenga habilitado el soporte para GPU en WSL2
- Asegúrate de tener los drivers NVIDIA más recientes instalados en Windows
- Ejecuta `nvidia-smi` en WSL2 para verificar que la GPU sea accesible

### El contenedor no inicia
- Verifica los logs: `docker compose logs comfyui`
- Asegúrate de que el puerto 8188 no esté en uso: `netstat -tuln | grep 8188`

### Error: pip no funciona o "externally-managed-environment"
- **Ubuntu 24.04 requiere usar un entorno virtual**
- Solución rápida: `./setup_venv.sh` (crea y configura el entorno virtual)
- O manualmente:
  ```bash
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  ```
- **IMPORTANTE:** Siempre activa el entorno virtual antes de usar pip:
  ```bash
  source venv/bin/activate  # Activar
  pip install ...          # Usar pip
  deactivate                # Desactivar cuando termines
  ```
- Si necesitas instalar python3-venv: `sudo apt-get install python3-venv python3-full`

## Recursos Adicionales

- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [LTX-Video en Hugging Face](https://huggingface.co/Lightricks/LTX-Video)
- [Documentación de Docker Compose](https://docs.docker.com/compose/)

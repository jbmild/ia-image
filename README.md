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

Si Python o pip no están instalados, ejecuta:

```bash
# Opción 1: Usar el script automático (Recomendado)
./install_python_pip.sh

# Opción 2: Instalación manual
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

# Actualizar pip
python3 -m pip install --upgrade pip --user
```

**Nota:** En Ubuntu/WSL2, usa `pip3` en lugar de `pip`, o crea un alias:
```bash
echo "alias pip='pip3'" >> ~/.bashrc
source ~/.bashrc
```

#### Instalar dependencias del proyecto

**Para usar `download_models.py` (Recomendado):**
```bash
pip3 install -r requirements.txt
# O manualmente:
pip3 install huggingface_hub>=0.20.0 tqdm>=4.66.0
```

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
# Instalar dependencias
pip install -r requirements.txt

# Ejecutar script de descarga
python download_models.py
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

### Error: pip no funciona o no está instalado
- **En WSL2/Ubuntu, usa `pip3` en lugar de `pip`**
- Instala pip: `sudo apt-get install python3-pip`
- O ejecuta el script: `./install_python_pip.sh`
- Si `pip` no funciona pero `pip3` sí, crea un alias:
  ```bash
  echo "alias pip='pip3'" >> ~/.bashrc
  source ~/.bashrc
  ```
- Verifica la instalación: `python3 -m pip --version`

## Recursos Adicionales

- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [LTX-Video en Hugging Face](https://huggingface.co/Lightricks/LTX-Video)
- [Documentación de Docker Compose](https://docs.docker.com/compose/)

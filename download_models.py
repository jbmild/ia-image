#!/usr/bin/env python3
"""
Script para descargar modelos necesarios para LTX-Video en ComfyUI
Usa huggingface_hub para descargar modelos de Hugging Face de forma eficiente.

Uso:
    python download_models.py

Requisitos:
    pip install huggingface_hub tqdm
"""

import os
import sys
from pathlib import Path
from typing import Optional

try:
    from huggingface_hub import hf_hub_download, snapshot_download
    from tqdm import tqdm
except ImportError:
    print("❌ Error: Faltan dependencias necesarias.")
    print("   Instala con: pip install huggingface_hub tqdm")
    sys.exit(1)


class Colors:
    """Códigos de color para terminal"""
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color


class ModelDownloader:
    """Descargador de modelos para LTX-Video"""
    
    def __init__(self, base_dir: str = "./comfyui_storage/models"):
        self.base_dir = Path(base_dir)
        self.diffusion_dir = self.base_dir / "diffusion_models"
        self.text_encoder_dir = self.base_dir / "text_encoders"
        self.vae_dir = self.base_dir / "vae"
        self.custom_nodes_dir = Path("./comfyui_storage/custom_nodes")
        
    def setup_directories(self):
        """Crear estructura de directorios necesaria"""
        directories = [
            self.diffusion_dir,
            self.text_encoder_dir,
            self.vae_dir,
            self.custom_nodes_dir
        ]
        
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
            
        print(f"{Colors.GREEN}✓{Colors.NC} Directorios creados/verificados")
        
    def download_file(self, repo_id: str, filename: str, 
                     local_dir: Path, repo_type: Optional[str] = None) -> bool:
        """
        Descargar un archivo específico de Hugging Face
        
        Args:
            repo_id: ID del repositorio en Hugging Face (ej: "Lightricks/LTX-Video")
            filename: Nombre del archivo a descargar
            local_dir: Directorio local donde guardar
            repo_type: Tipo de repositorio (None para modelos, "space" para espacios)
        """
        local_file = local_dir / filename
        
        # Verificar si el archivo ya existe
        if local_file.exists():
            size_mb = local_file.stat().st_size / (1024 * 1024)
            print(f"{Colors.GREEN}✓{Colors.NC} {filename} ya existe ({size_mb:.1f} MB)")
            return True
            
        print(f"{Colors.BLUE}⏳{Colors.NC} Descargando {filename}...")
        
        try:
            downloaded_path = hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                local_dir=local_dir,
                repo_type=repo_type,
                local_dir_use_symlinks=False,
                resume_download=True
            )
            
            print(f"{Colors.GREEN}✓{Colors.NC} Descargado: {filename}")
            return True
            
        except Exception as e:
            print(f"{Colors.RED}✗{Colors.NC} Error descargando {filename}: {e}")
            return False
    
    def download_repo(self, repo_id: str, local_dir: Path, 
                     allow_patterns: Optional[list] = None) -> bool:
        """
        Descargar todo un repositorio o archivos que coincidan con patrones
        
        Args:
            repo_id: ID del repositorio en Hugging Face
            local_dir: Directorio local donde guardar
            allow_patterns: Lista de patrones de archivos a descargar (ej: ["*.safetensors"])
        """
        print(f"{Colors.BLUE}⏳{Colors.NC} Descargando repositorio {repo_id}...")
        
        try:
            snapshot_download(
                repo_id=repo_id,
                local_dir=local_dir,
                allow_patterns=allow_patterns,
                local_dir_use_symlinks=False,
                resume_download=True
            )
            
            print(f"{Colors.GREEN}✓{Colors.NC} Repositorio descargado: {repo_id}")
            return True
            
        except Exception as e:
            print(f"{Colors.RED}✗{Colors.NC} Error descargando repositorio {repo_id}: {e}")
            return False
    
    def download_ltx_video_model(self) -> bool:
        """Descargar modelo principal LTX-Video"""
        print(f"\n{Colors.BLUE}1. Modelo Principal LTX-Video{Colors.NC}")
        print("   Repositorio: Lightricks/LTX-Video")
        
        # Intentar descargar archivos .safetensors del modelo
        # Primero intentamos descargar archivos específicos comunes
        success = False
        
        # Lista de posibles nombres de archivos del modelo
        possible_files = [
            "ltx-video-2b-v0.5.safetensors",
            "ltx-video.safetensors",
            "model.safetensors",
            "diffusion_pytorch_model.safetensors"
        ]
        
        for filename in possible_files:
            if self.download_file(
                repo_id="Lightricks/LTX-Video",
                filename=filename,
                local_dir=self.diffusion_dir
            ):
                success = True
                break
        
        # Si no encontramos archivos específicos, intentamos descargar todo el repo
        if not success:
            print(f"{Colors.YELLOW}⚠{Colors.NC} Intentando descargar todo el repositorio...")
            success = self.download_repo(
                repo_id="Lightricks/LTX-Video",
                local_dir=self.diffusion_dir,
                allow_patterns=["*.safetensors", "*.ckpt", "*.pt"]
            )
        
        return success
    
    def download_t5_encoder(self) -> bool:
        """Descargar Text Encoder T5-XXL (versión cuantizada para 8GB VRAM)"""
        print(f"\n{Colors.BLUE}2. Text Encoder T5-XXL (FP8 cuantizado){Colors.NC}")
        print("   Optimizado para GPUs de 8GB VRAM")
        
        # T5-XXL estándar (muy grande, ~11GB)
        # Para 8GB VRAM, necesitamos una versión cuantizada
        # Intentamos varias opciones:
        
        repos_to_try = [
            ("google/t5-v1_1-xxl", ["model.safetensors", "pytorch_model.bin"]),
            ("google/flan-t5-xxl", ["model.safetensors", "pytorch_model.bin"]),
        ]
        
        success = False
        for repo_id, filenames in repos_to_try:
            for filename in filenames:
                if self.download_file(
                    repo_id=repo_id,
                    filename=filename,
                    local_dir=self.text_encoder_dir
                ):
                    success = True
                    break
            if success:
                break
        
        # Si no encontramos, intentamos descargar todo el repo
        if not success:
            print(f"{Colors.YELLOW}⚠{Colors.NC} Intentando descargar repositorio completo...")
            for repo_id, _ in repos_to_try:
                if self.download_repo(
                    repo_id=repo_id,
                    local_dir=self.text_encoder_dir,
                    allow_patterns=["*.safetensors", "*.bin", "*.pt"]
                ):
                    success = True
                    break
        
        if not success:
            print(f"{Colors.YELLOW}⚠{Colors.NC} No se pudo descargar T5-XXL automáticamente.")
            print(f"   {Colors.YELLOW}→{Colors.NC} Descarga manual desde: https://huggingface.co/google/t5-v1_1-xxl")
            print(f"   {Colors.YELLOW}→{Colors.NC} O busca una versión cuantizada en FP8")
        
        return success
    
    def download_vae(self) -> bool:
        """Descargar VAE si es necesario"""
        print(f"\n{Colors.BLUE}3. VAE (Opcional){Colors.NC}")
        
        # Algunos modelos incluyen el VAE, otros no
        # Intentamos descargar VAE común de Stable Diffusion
        success = self.download_file(
            repo_id="stabilityai/sd-vae-ft-mse",
            filename="diffusion_pytorch_model.safetensors",
            local_dir=self.vae_dir
        )
        
        if not success:
            print(f"{Colors.YELLOW}⚠{Colors.NC} VAE opcional, puede no ser necesario")
        
        return True  # No es crítico
    
    def install_custom_nodes(self) -> bool:
        """Instalar nodos personalizados ComfyUI-LTXVideo"""
        print(f"\n{Colors.BLUE}4. Nodos Personalizados ComfyUI-LTXVideo{Colors.NC}")
        
        nodes_dir = self.custom_nodes_dir / "ComfyUI-LTXVideo"
        
        if nodes_dir.exists():
            print(f"{Colors.GREEN}✓{Colors.NC} ComfyUI-LTXVideo ya está instalado")
            return True
        
        print(f"{Colors.BLUE}⏳{Colors.NC} Clonando repositorio de nodos...")
        
        try:
            import subprocess
            result = subprocess.run(
                ["git", "clone", "https://github.com/Lightricks/ComfyUI-LTXVideo.git", 
                 str(nodes_dir)],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"{Colors.GREEN}✓{Colors.NC} Nodos personalizados instalados")
                return True
            else:
                print(f"{Colors.RED}✗{Colors.NC} Error clonando repositorio: {result.stderr}")
                print(f"   {Colors.YELLOW}→{Colors.NC} Asegúrate de tener git instalado")
                return False
                
        except FileNotFoundError:
            print(f"{Colors.RED}✗{Colors.NC} Git no está instalado")
            print(f"   {Colors.YELLOW}→{Colors.NC} Instala git: sudo apt-get install git")
            return False
        except Exception as e:
            print(f"{Colors.RED}✗{Colors.NC} Error: {e}")
            return False
    
    def print_summary(self):
        """Mostrar resumen de archivos descargados"""
        print(f"\n{Colors.BLUE}{'='*60}{Colors.NC}")
        print(f"{Colors.GREEN}✓ Descarga completada{Colors.NC}")
        print(f"{Colors.BLUE}{'='*60}{Colors.NC}\n")
        
        # Calcular tamaños
        total_size = 0
        file_count = 0
        
        for directory in [self.diffusion_dir, self.text_encoder_dir, self.vae_dir]:
            if directory.exists():
                for file in directory.rglob("*"):
                    if file.is_file():
                        total_size += file.stat().st_size
                        file_count += 1
        
        total_size_gb = total_size / (1024 ** 3)
        
        print(f"📊 Archivos descargados: {file_count}")
        print(f"💾 Tamaño total: {total_size_gb:.2f} GB")
        print(f"📁 Ubicación: {self.base_dir.absolute()}\n")
        
        if total_size_gb > 0:
            print(f"{Colors.YELLOW}⚠{Colors.NC} Asegúrate de tener suficiente espacio en disco")
            print(f"   Los modelos pueden ocupar 30-40GB en total\n")
    
    def run(self):
        """Ejecutar descarga completa de modelos"""
        print(f"{Colors.BLUE}{'='*60}{Colors.NC}")
        print(f"{Colors.BLUE}🎬 Descargador de Modelos LTX-Video{Colors.NC}")
        print(f"{Colors.BLUE}{'='*60}{Colors.NC}\n")
        
        self.setup_directories()
        
        results = {
            "ltx_video": self.download_ltx_video_model(),
            "t5_encoder": self.download_t5_encoder(),
            "vae": self.download_vae(),
            "custom_nodes": self.install_custom_nodes()
        }
        
        self.print_summary()
        
        # Verificar resultados críticos
        if not results["ltx_video"]:
            print(f"{Colors.RED}❌ Error: No se pudo descargar el modelo principal LTX-Video{Colors.NC}")
            print(f"   {Colors.YELLOW}→{Colors.NC} Descarga manual desde: https://huggingface.co/Lightricks/LTX-Video")
            return False
        
        print(f"{Colors.GREEN}✅ Modelos listos para usar{Colors.NC}")
        print(f"\n{Colors.BLUE}Próximo paso:{Colors.NC} docker compose up -d")
        
        return True


def main():
    """Función principal"""
    downloader = ModelDownloader()
    success = downloader.run()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

#!/bin/bash
# =============================================================================
# setup_env.sh - Preparação do ambiente GitHub Codespaces para build da ISO
# =============================================================================
# Este script instala todas as dependências necessárias e cria a estrutura
# inicial do live-build para construção da distribuição Linux customizada.
# =============================================================================

set -e

echo "=========================================="
echo "Setup Environment for Custom Debian ISO"
echo "=========================================="

# Verificar se está rodando como root (necessário para live-build)
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Este script deve ser executado como root (sudo)"
    exit 1
fi

# Atualizar repositórios
echo "[1/5] Atualizando repositórios..."
apt-get update -qq

# Instalar dependências essenciais para o build
echo "[2/5] Instalando dependências do live-build..."
apt-get install -y \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-common \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    qemu-user-static \
    binfmt-support \
    wget \
    curl \
    git \
    zip \
    unzip \
    ca-certificates \
    gnupg \
    apt-utils \
    rsync

# Configurar arquitetura (amd64 por padrão)
echo "[3/5] Configurando arquitetura do sistema..."
export LB_ARCH="amd64"

# Criar estrutura de diretórios do live-build
echo "[4/5] Criando estrutura de diretórios do live-build..."
LB_DIR="./live-build-config"

if [ -d "$LB_DIR" ]; then
    echo "Diretório $LB_DIR já existe. Limpando..."
    rm -rf "$LB_DIR"
fi

mkdir -p "$LB_DIR"
cd "$LB_DIR"

# Inicializar configuração do live-build
lb config \
    --mode debian \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main contrib non-free non-free-firmware" \
    --debian-installer none \
    --initramfs-compressor gzip \
    --bootappend-live "boot=live components quiet splash" \
    --iso-application "Custom Debian GNOME" \
    --iso-preparer "Custom ISO Builder" \
    --iso-publisher "Custom Linux Project" \
    --iso-volume "CUSTOM_DEBIAN_GNOME" \
    --binary-images iso-hybrid

# Criar estrutura de diretórios customizados
echo "[5/5] Criando estrutura de diretórios customizados..."

# Diretórios de configuração
mkdir -p config/package-lists
mkdir -p config/hooks/live
mkdir -p config/hooks/chroot
mkdir -p config/includes.chroot
mkdir -p config/includes.binary
mkdir -p config/archives
mkdir -p config/materials

# Copiar scripts de hook e listas de pacotes para a estrutura
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copiar lista de pacotes
if [ -f "$SCRIPT_DIR/config/package-lists/my_packages.list.chroot" ]; then
    cp "$SCRIPT_DIR/config/package-lists/my_packages.list.chroot" config/package-lists/
    echo "Lista de pacotes copiada."
fi

# Copiar hooks
if [ -f "$SCRIPT_DIR/config/hooks/live/customize_gnome.chroot" ]; then
    cp "$SCRIPT_DIR/config/hooks/live/customize_gnome.chroot" config/hooks/live/
    chmod +x config/hooks/live/customize_gnome.chroot
    echo "Hook de customização GNOME copiado."
fi

if [ -f "$SCRIPT_DIR/config/hooks/live/setup_skel.chroot" ]; then
    cp "$SCRIPT_DIR/config/hooks/live/setup_skel.chroot" config/hooks/live/
    chmod +x config/hooks/live/setup_skel.chroot
    echo "Hook de configuração SKEL copiado."
fi

# Voltar ao diretório original
cd ..

echo ""
echo "=========================================="
echo "Setup concluído com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Execute: ./build.sh"
echo "2. Aguarde o processo de build (pode levar 30-60 minutos)"
echo "3. A ISO será gerada em: ./output/"
echo ""

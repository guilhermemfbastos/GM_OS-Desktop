#!/bin/bash
# =============================================================================
# build.sh - Script principal de construção da ISO customizada
# =============================================================================
# Este script orquestra todo o processo de build:
# 1. Limpa builds anteriores
# 2. Configura o live-build com parâmetros personalizados
# 3. Copia arquivos de configuração customizados
# 4. Executa o build da ISO
# 5. Move a ISO para pasta de output e exibe informações
# =============================================================================

set -e

echo "=========================================="
echo "Custom Debian GNOME ISO Builder"
echo "=========================================="
echo ""

# Variáveis de configuração (editáveis)
DEBIAN_RELEASE="${DEBIAN_RELEASE:-bookworm}"  # bookworm ou trixie
ARCHITECTURE="${ARCHITECTURE:-amd64}"
ISO_NAME="${ISO_NAME:-custom-debian-gnome}"
OUTPUT_DIR="./output"
LB_DIR="./live-build-config"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# -----------------------------------------------------------------------------
# 1. VERIFICAÇÕES PRELIMINARES
# -----------------------------------------------------------------------------
print_info "Verificando pré-requisitos..."

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script deve ser executado como root (use: sudo ./build.sh)"
    exit 1
fi

# Verificar se live-build está instalado
if ! command -v lb &> /dev/null; then
    print_error "live-build não está instalado. Execute primeiro: ./setup_env.sh"
    exit 1
fi

# Verificar espaço em disco disponível
DISK_AVAILABLE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$DISK_AVAILABLE" -lt 15 ]; then
    print_warning "Espaço em disco baixo: ${DISK_AVAILABLE}GB disponíveis. Recomenda-se pelo menos 15GB."
fi

print_success "Pré-requisitos verificados!"
echo ""

# -----------------------------------------------------------------------------
# 2. LIMPAR BUILDS ANTERIORES
# -----------------------------------------------------------------------------
print_info "Limpando builds anteriores..."

cd "$(dirname "$0")"

if [ -d "$LB_DIR" ]; then
    cd "$LB_DIR"
    lb clean --purge 2>/dev/null || true
    cd ..
    print_success "Build anterior limpo."
else
    print_info "Nenhum build anterior encontrado."
fi

echo ""

# -----------------------------------------------------------------------------
# 3. CONFIGURAR LIVE-BUILD
# -----------------------------------------------------------------------------
print_info "Configurando live-build para Debian $DEBIAN_RELEASE..."

mkdir -p "$LB_DIR"
cd "$LB_DIR"

lb config \
    --mode debian \
    --architectures "$ARCHITECTURE" \
    --distribution "$DEBIAN_RELEASE" \
    --archive-areas "main contrib non-free non-free-firmware" \
    --debian-installer none \
    --initramfs-compressor gzip \
    --bootappend-live "boot=live components quiet splash nomodeset" \
    --iso-application "Custom Debian GNOME" \
    --iso-preparer "Custom ISO Builder v1.0" \
    --iso-publisher "Custom Linux Project" \
    --iso-volume "${ISO_NAME^^}" \
    --binary-images iso-hybrid \
    --memtest none \
    --debian-installer-distribution "$DEBIAN_RELEASE" \
    --security true \
    --updates true \
    --backports false \
    --recommends false \
    --apt false \
    --apt-individual-lists true \
    --cache false \
    --debootstrap-options "--include=ca-certificates,apt-transport-https"

print_success "Live-build configurado!"
echo ""

# -----------------------------------------------------------------------------
# 4. COPIAR ARQUIVOS CUSTOMIZADOS
# -----------------------------------------------------------------------------
print_info "Copiando arquivos de configuração customizados..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Criar estrutura de diretórios se não existir
mkdir -p config/package-lists
mkdir -p config/hooks/live
mkdir -p config/hooks/chroot
mkdir -p config/includes.chroot
mkdir -p config/includes.binary

# Copiar lista de pacotes
if [ -f "$SCRIPT_DIR/config/package-lists/my_packages.list.chroot" ]; then
    cp "$SCRIPT_DIR/config/package-lists/my_packages.list.chroot" config/package-lists/
    print_success "Lista de pacotes copiada."
else
    print_warning "Lista de pacotes não encontrada em config/package-lists/my_packages.list.chroot"
fi

# Copiar hooks do live
for hook in customize_gnome.chroot setup_skel.chroot; do
    if [ -f "$SCRIPT_DIR/config/hooks/live/$hook" ]; then
        cp "$SCRIPT_DIR/config/hooks/live/$hook" config/hooks/live/
        chmod +x config/hooks/live/$hook
        print_success "Hook $hook copiado."
    else
        print_warning "Hook $hook não encontrado."
    fi
done

# Criar arquivo de remoção de pacotes (negative list)
cat > config/package-lists/my_remove.list.chroot << 'REMOVEEOF'
# Jogos e bloatware do GNOME
aisleriot
gnome-sudoku
gnome-mahjongg
gnome-mines
gnome-taquin
gnome-tetravex
gnome-2048
gnome-klotski
hitori
iagno
lightsoff
quadrapassel
swell-foop
tali
gnome-maps
gnome-weather
gnome-calendar
gnome-contacts
gnome-characters
gnome-font-viewer
gnome-remote-desktop
gnome-user-share
gnome-online-accounts-gtk
gnome-shell-extension-ubuntu-dock
REMOVEEOF

print_success "Lista de remoção criada."

# Copiar materiais adicionais (wallpapers, etc.)
if [ -d "$SCRIPT_DIR/config/materials" ] && [ "$(ls -A "$SCRIPT_DIR/config/materials" 2>/dev/null)" ]; then
    cp -r "$SCRIPT_DIR/config/materials/"* config/materials/ 2>/dev/null || true
    print_success "Materiais adicionais copiados."
fi

cd ..

echo ""

# -----------------------------------------------------------------------------
# 5. EXECUTAR BUILD
# -----------------------------------------------------------------------------
print_info "Iniciando build da ISO..."
print_warning "Este processo pode levar de 30 a 60 minutos dependendo da sua conexão e hardware."
echo ""

cd "$LB_DIR"

# Executar o build
sudo lb build 2>&1 | tee ../build.log

# Verificar se o build foi bem sucedido
if [ $? -eq 0 ]; then
    print_success "Build concluído com sucesso!"
else
    print_error "Build falhou! Verifique o arquivo build.log para detalhes."
    exit 1
fi

cd ..

echo ""

# -----------------------------------------------------------------------------
# 6. MOVER ISO PARA PASTA DE OUTPUT
# -----------------------------------------------------------------------------
print_info "Processando imagem ISO final..."

# Criar diretório de output
mkdir -p "$OUTPUT_DIR"

# Encontrar e mover a ISO gerada
ISO_SOURCE=""
for iso_file in "$LB_DIR"/*.iso "$LB_DIR"/live-image-*.iso "$LB_DIR"/debian-live-*.iso; do
    if [ -f "$iso_file" ]; then
        ISO_SOURCE="$iso_file"
        break
    fi
done

if [ -n "$ISO_SOURCE" ] && [ -f "$ISO_SOURCE" ]; then
    # Gerar nome final com timestamp
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ISO_FINAL="${OUTPUT_DIR}/${ISO_NAME}-${DEBIAN_RELEASE}-${TIMESTAMP}.iso"
    
    # Copiar ISO para output
    cp "$ISO_SOURCE" "$ISO_FINAL"
    
    # Calcular checksums
    print_info "Calculando checksums..."
    md5sum "$ISO_FINAL" > "${ISO_FINAL}.md5"
    sha256sum "$ISO_FINAL" > "${ISO_FINAL}.sha256"
    
    # Obter tamanho do arquivo
    ISO_SIZE=$(du -h "$ISO_FINAL" | cut -f1)
    ISO_SIZE_BYTES=$(stat -c%s "$ISO_FINAL")
    
    echo ""
    echo "=========================================="
    print_success "ISO GERADA COM SUCESSO!"
    echo "=========================================="
    echo ""
    echo "Arquivo: $(basename "$ISO_FINAL")"
    echo "Localização: $(realpath "$ISO_FINAL")"
    echo "Tamanho: ${ISO_SIZE} (${ISO_SIZE_BYTES} bytes)"
    echo ""
    echo "Checksums:"
    echo "  MD5:    $(cat "${ISO_FINAL}.md5" | cut -d' ' -f1)"
    echo "  SHA256: $(cat "${ISO_FINAL}.sha256" | cut -d' ' -f1)"
    echo ""
    echo "=========================================="
    echo ""
    
    # Listar arquivos no output
    print_info "Arquivos na pasta de output:"
    ls -lh "$OUTPUT_DIR/"
    
else
    print_error "Nenhuma ISO foi gerada. Verifique o log do build."
    exit 1
fi

echo ""
print_info "Build completo! Você pode encontrar a ISO em: $OUTPUT_DIR/"
echo ""

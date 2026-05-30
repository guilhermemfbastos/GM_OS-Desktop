# Custom Debian GNOME ISO Builder

Distribuição Linux personalizada baseada no Debian com GNOME fortemente customizado, desenvolvida para ser construída no GitHub Codespaces.

## 📋 Visão Geral

Este projeto cria uma ISO bootável do Debian com:
- **Base:** Debian Bookworm (ou Trixie, configurável)
- **Interface:** GNOME Core minimalista
- **Tema:** WhiteSur Dark (moderno, estilo macOS)
- **Ícones:** Papirus Dark
- **Cursores:** Capitaine Cursors
- **Extensões GNOME pré-instaladas:**
  - Dash to Dock
  - Blur my Shell
  - User Themes
  - Just Perfection

## 🚀 Quick Start

### No GitHub Codespaces:

```bash
# 1. Clone o repositório (já estará clonado no seu Codespace)
cd /workspace

# 2. Dê permissão de execução aos scripts
chmod +x setup_env.sh build.sh

# 3. Execute o setup (instala dependências)
sudo ./setup_env.sh

# 4. Execute o build da ISO
sudo ./build.sh

# 5. Aguarde (30-60 minutos). A ISO será gerada em ./output/
```

### Variáveis de Ambiente Opcionais

```bash
# Para usar Debian Testing (Trixie) ao invés de Stable (Bookworm):
export DEBIAN_RELEASE=trixie

# Para mudar o nome da ISO:
export ISO_NAME=minha-distro-custom

# Executar o build:
sudo ./build.sh
```

## 📁 Estrutura do Projeto

```
/workspace/
├── setup_env.sh                          # Script de preparação do ambiente
├── build.sh                              # Script principal de build
├── config/
│   ├── package-lists/
│   │   └── my_packages.list.chroot      # Lista de pacotes a instalar
│   └── hooks/live/
│       ├── customize_gnome.chroot       # Customização do GNOME (in-chroot)
│       └── setup_skel.chroot            # Configuração do /etc/skel
├── live-build-config/                    # Diretório gerado pelo live-build
└── output/                               # ISO gerada aparecerá aqui
```

## ⚙️ Personalização

### Alterar Pacotes

Edite `config/package-lists/my_packages.list.chroot` para adicionar ou remover pacotes da instalação.

### Alterar Temas e Extensões

Edite `config/hooks/live/customize_gnome.chroot` para:
- Mudar URLs de temas
- Adicionar/remover extensões do GNOME
- Modificar configurações do dconf

### Alterar Wallpaper

O wallpaper padrão é gerado dinamicamente (SVG gradiente). Para usar uma imagem personalizada:

1. Coloque sua imagem em `config/materials/wallpaper.png`
2. Modifique o hook `customize_gnome.chroot` para copiar este arquivo

## 🔧 Requisitos do Sistema

Para build local (fora do Codespaces):
- **RAM:** Mínimo 4GB (recomendado 8GB+)
- **Disco:** Mínimo 15GB livres
- **SO:** Linux (Debian/Ubuntu recomendado)
- **Privilégios:** Root/sudo necessário

## 🐛 Troubleshooting

### Build falha por falta de espaço
```bash
# Limpar builds anteriores
cd live-build-config && lb clean --purge
```

### Erro ao baixar extensões do GNOME
Verifique sua conexão de rede. As extensões são baixadas do GitHub e extensions.gnome.org.

### ISO muito grande
Remova pacotes desnecessários da lista `my_packages.list.chroot` ou use `gnome-core` em vez de `gnome`.

## 📝 Notas Importantes

1. **Build no Codespaces:** O processo pode consumir bastante资源. Monitore o uso no dashboard do Codespaces.

2. **Tempo de Build:** Primeiro build pode levar 30-60 minutos. Builds subsequentes são mais rápidos devido ao cache.

3. **ISO Híbrida:** A ISO gerada é híbrida (boot via BIOS e UEFI).

4. **Live System:** O sistema é "live" - roda direto da ISO sem instalação. Para instalar permanentemente, use o instalador padrão do Debian após o boot.

## 📄 Licença

Este projeto segue a mesma licença do Debian (DFSG).

## 🤝 Contribuições

Sinta-se à vontade para abrir issues e pull requests para melhorias.

---

**Desenvolvido para demonstrar criação de distribuições Linux personalizadas baseadas no Debian.**

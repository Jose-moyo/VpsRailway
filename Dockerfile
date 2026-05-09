FROM debian:bookworm-slim

# 1. Configuration système et locales (essentiel pour éviter les bugs d'affichage)
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/zsh \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates wget curl git sudo \
        python3 python3-pip zsh locales \
        tini neofetch vim nano procps psmisc \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Installation de ttyd (v1.7.7 est la plus stable)
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64|amd64) ttyd_asset="ttyd.x86_64" ;; \
      aarch64|arm64) ttyd_asset="ttyd.aarch64" ;; \
      *) echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/1.7.7/${ttyd_asset}" && \
    chmod +x /usr/local/bin/ttyd

# 3. Création de l'utilisateur sécurisé 'debian'
RUN useradd -m -s /bin/zsh debian && \
    echo "debian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER debian
WORKDIR /home/debian

# 4. Installation de Oh My Zsh + Plugins (Auto-suggestions et Highlight)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 5. Configuration visuelle (Thème 'robbyrussell' car plus compatible navigateur que 'agnoster')
RUN sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc && \
    echo "neofetch" >> ~/.zshrc && \
    echo "export PS1='%n@terminal:%~# '" >> ~/.zshrc

# Port par défaut pour Railway
EXPOSE ${PORT:-8080}

ENTRYPOINT ["/usr/bin/tini", "--"]

# 6. Commande de lancement avec sécurité renforcée
# Note : 'zsh -i' force le chargement du profil interactif
CMD ["/bin/sh", "-c", "/usr/local/bin/ttyd --writable -i 0.0.0.0 -p ${PORT:-8080} -c ${USERNAME:-admin}:${PASSWORD:-railway} zsh -i"]

FROM debian:bookworm-slim

# 1. Configuration système et locales
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/zsh \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates wget curl git sudo \
        python3 python3-pip zsh locales \
        tini neofetch vim nano procps psmisc \
        ttyd \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Création de l'utilisateur sécurisé 'debian'
RUN useradd -m -s /bin/zsh debian && \
    echo "debian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER debian
WORKDIR /home/debian

# 3. Installation de Oh My Zsh + Plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 4. Configuration visuelle
RUN sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc && \
    echo "neofetch" >> ~/.zshrc && \
    echo "export PS1='%n@terminal:%~# '" >> ~/.zshrc

# Port par défaut pour Railway
EXPOSE ${PORT:-8080}

ENTRYPOINT ["/usr/bin/tini", "--"]

# 5. Commande de lancement (Utilisation de /bin/sh pour supporter les variables comme $PORT)
CMD ["/bin/sh", "-c", "/usr/bin/ttyd --writable -i 0.0.0.0 -p ${PORT:-8080} -c ${USERNAME:-admin}:${PASSWORD:-railway} zsh -i"]



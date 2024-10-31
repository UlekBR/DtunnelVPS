#!/bin/bash
# rustyproxy Installer

TOTAL_STEPS=9
CURRENT_STEP=0

show_progress() {
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo "Progresso: [${PERCENT}%] - $1"
}

error_exit() {
    echo -e "\nErro: $1"
    exit 1
}

increment_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

if [ "$EUID" -ne 0 ]; then
    error_exit "EXECUTE COMO ROOT"
else
    clear
    show_progress "Atualizando repositorios..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y > /dev/null 2>&1 || error_exit "Falha ao atualizar os repositorios"
    increment_step

    # ---->>>> Verificação do sistema
    show_progress "Verificando o sistema..."
    if ! command -v lsb_release &> /dev/null; then
        apt install lsb-release -y > /dev/null 2>&1 || error_exit "Falha ao instalar lsb-release"
    fi
    increment_step

    # ---->>>> Verificação do sistema
    OS_NAME=$(lsb_release -is)
    VERSION=$(lsb_release -rs)

    case $OS_NAME in
        Ubuntu)
            case $VERSION in
                24.*|22.*|20.*)
                    show_progress "Sistema Ubuntu suportado, continuando..."
                    ;;
                *)
                    error_exit "Versão do Ubuntu não suportada. Use 20, 22 ou 24."
                    ;;
            esac
            ;;
        Debian)
            case $VERSION in
                12*|11*)
                    show_progress "Sistema Debian suportado, continuando..."
                    ;;
                *)
                    error_exit "Versão do Debian não suportada. 11 ou 12."
                    ;;
            esac
            ;;
        *)
            error_exit "Sistema não suportado. Use Ubuntu ou Debian."
            ;;
    esac
    increment_step

    # ---->>>> Instalação de pacotes requisitos e atualização do sistema
    show_progress "Atualizando o sistema..."
    apt upgrade -y > /dev/null 2>&1 || error_exit "Falha ao atualizar o sistema"
    apt-get install curl build-essential git -y > /dev/null 2>&1 || error_exit "Falha ao instalar pacotes"
    increment_step

    # ---->>>> Criando o diretório do script
    show_progress "Criando diretorio /opt/dtunnelmod..."
    mkdir -p /opt/dtunnelmod > /dev/null 2>&1
    increment_step

    # ---->>>> Instalar node
    show_progress "Instalando nodejs 18..."
    if ! command -v node &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash > /dev/null 2>&1 || error_exit "Falha ao instalar NodeJS"
        source "/root/.bashrc"
        nvm install 18
        npm install -g typescript
        npm install
    fi
    increment_step

    # ---->>>> Instalar o DtunnelMOD Painel
    show_progress "Instalando DtunnelMOD Painel, isso pode levar algum tempo dependendo da maquina..."

    if [ -d "/root/DtunnelVPS" ]; then
        rm -rf /root/DtunnelVPS
    fi
    git clone --branch "main" https://github.com/UlekBR/DtunnelVPS.git /root/DtunnelVPS > /dev/null 2>&1 || error_exit "Falha ao clonar o painel dtunnel"
    mv /root/DtunnelVPS/menu.sh /opt/dtunnelmod/menu
    cd /root/DtunnelVPS/Dtunnel
    npx prisma generate
    npx prisma migrate deploy
    mv . /opt/dtunnelmod
    increment_step

    # ---->>>> Configuração de permissões
    show_progress "Configurando permissões..."
    chmod +x /opt/dtunnelmod/menu
    ln -sf /opt/dtunnelmod/menu /usr/local/bin/dtunnelpainel
    increment_step

    # ---->>>> Limpeza
    show_progress "Limpando diretórios temporários..."
    cd /root/
    rm -rf /root/DtunnelVPS/
    increment_step

    # ---->>>> Instalação finalizada :)
    echo "Instalação concluída com sucesso. Digite 'dtunnelpainel' para acessar o menu."
fi
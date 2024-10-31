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
    exit 0
}

increment_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

if [ "$EUID" -ne 0 ]; then
    error_exit "EXECUTE COMO ROOT"
else
    clear
    show_progress "Atualizando repositórios..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1 || error_exit "Falha ao atualizar os repositórios"
    increment_step

    # ---->>>> Verificação do sistema
    show_progress "Verificando o sistema..."
    if ! command -v lsb_release &> /dev/null; then
        apt install lsb-release -y >/dev/null 2>&1 || error_exit "Falha ao instalar lsb-release"
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
    apt upgrade -y >/dev/null 2>&1 || error_exit "Falha ao atualizar o sistema"
    apt-get install wget git -y >/dev/null 2>&1 || error_exit "Falha ao instalar pacotes"
    increment_step

    # ---->>>> Criando o diretório do script
    show_progress "Criando diretório /opt/dtunnelmod..."
    mkdir -p /opt/dtunnelmod >/dev/null 2>&1 || error_exit "Falha ao criar o diretório"
    increment_step

    # ---->>>> Instalar Node.js
    show_progress "Instalando Node.js 18..."
    bash <(wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh) >/dev/null 2>&1 || error_exit "Falha ao instalar NVM"
    [ -s "/root/.nvm/nvm.sh" ] && \. "/root/.nvm/nvm.sh" || error_exit "Falha ao carregar NVM"
    nvm install 18 >/dev/null 2>&1 || error_exit "Falha ao instalar Node.js"

    increment_step

    # ---->>>> Instalar o DtunnelMOD Painel
    show_progress "Instalando DtunnelMOD Painel, isso pode levar algum tempo dependendo da máquina..."
    git clone --branch "main" https://github.com/UlekBR/DtunnelVPS.git /root/DtunnelVPS >/dev/null 2>&1 || error_exit "Falha ao clonar o painel dtunnel"
    mv /root/DtunnelVPS/menu /opt/dtunnelmod/menu || error_exit "Falha ao mover o menu"
    cd /root/DtunnelVPS/DTunnel/ || error_exit "Falha ao entrar no diretório DTunnel"
    npm install -g typescript >/dev/null 2>&1 || error_exit "Falha ao instalar TypeScript"
    npm install --force >/dev/null 2>&1 || error_exit "Falha ao instalar pacotes do DtunnelMOD"
    
    mv /root/DtunnelVPS/DTunnel/* /opt/dtunnelmod/ || error_exit "Falha ao mover arquivos do DtunnelVPS"
    increment_step

    # ---->>>> Configuração de permissões
    show_progress "Configurando permissões..."
    chmod +x /opt/dtunnelmod/menu || error_exit "Falha ao configurar permissões"
    ln -sf /opt/dtunnelmod/menu /usr/local/bin/dtunnelpainel || error_exit "Falha ao criar link simbólico"
    increment_step

    # ---->>>> Limpeza
    show_progress "Limpando diretórios temporários..."
    rm -rf /root/DtunnelVPS/ || error_exit "Falha ao limpar diretório temporário"
    increment_step

    # ---->>>> Instalação finalizada :)
    echo "Instalação concluída com sucesso. Digite 'dtunnelpainel' para acessar o menu."
fi

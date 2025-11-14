#!/bin/bash

tools_dir="/opt/BA_tools"
sudo mkdir "${tools_dir}" 2>/dev/null
sudo chown -R "$(whoami)":"$(whoami)" "${tools_dir}"

sudo apt-get update

# Install Docker CE
echo "Installing Docker CE..."
if ! command -v docker &> /dev/null; then
    # Remove conflicting packages
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y "$pkg" || true; done

    # Detect distribution and codename
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"

        # For Ubuntu derivatives (Mint, Pop!_OS, etc.), use UBUNTU_CODENAME if available
        if [ "$ID" = "ubuntu" ] || [ "$ID_LIKE" = "ubuntu" ] || echo "$ID_LIKE" | grep -q "ubuntu"; then
            DOCKER_DISTRO="ubuntu"
            DOCKER_CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

            # Validate against supported Ubuntu versions
            case "$DOCKER_CODENAME" in
                oracular|plucky|noble|jammy)
                    # Officially supported Ubuntu versions (25.10, 25.04, 24.04 LTS, 22.04 LTS)
                    ;;
                *)
                    echo "Warning: Ubuntu codename '$DOCKER_CODENAME' is not officially supported by Docker. Falling back to Bookworm."
                    DOCKER_DISTRO="debian"
                    DOCKER_CODENAME="bookworm"
                    ;;
            esac
        elif [ "$ID" = "debian" ] || [ "$ID" = "kali" ] || echo "$ID_LIKE" | grep -q "debian"; then
            DOCKER_DISTRO="debian"
            DOCKER_CODENAME="$VERSION_CODENAME"

            # Validate against supported Debian versions
            case "$DOCKER_CODENAME" in
                trixie|bookworm|bullseye)
                    # Officially supported Debian versions (13, 12, 11)
                    ;;
                kali-rolling)
                    # Kali uses Debian repos, default to bookworm
                    DOCKER_CODENAME="bookworm"
                    ;;
                *)
                    echo "Warning: Debian codename '$DOCKER_CODENAME' is not officially supported by Docker. Falling back to Bookworm."
                    DOCKER_CODENAME="bookworm"
                    ;;
            esac
        else
            echo "Warning: Unknown distribution '$ID'. Falling back to Debian Bookworm."
            DOCKER_DISTRO="debian"
            DOCKER_CODENAME="bookworm"
        fi
    else
        echo "Warning: Cannot detect distribution. Falling back to Debian Bookworm."
        DOCKER_DISTRO="debian"
        DOCKER_CODENAME="bookworm"
    fi

    echo "Using Docker repository: $DOCKER_DISTRO/$DOCKER_CODENAME"

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/$DOCKER_DISTRO/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DOCKER_DISTRO $DOCKER_CODENAME stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker CE and components
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker service
    sudo systemctl enable docker || true
    sudo systemctl start docker || true

    echo "Docker CE installed and started successfully."
else
    echo "Docker is already installed"
fi

# Configure Docker group and permissions
echo "Configuring Docker group and permissions..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
if [[ -d "$HOME/.docker" ]]; then
    sudo chown "$USER":"$USER" "$HOME/.docker" -R
    sudo chmod g+rwx "$HOME/.docker" -R
fi
echo "NOTE: You need to log out and log back in for docker group membership to take effect"
echo "      Or run: newgrp docker"

# Install pipx
if ! command -v pipx &> /dev/null; then
    sudo apt-get install -y pipx
fi

# Install uv
if ! command -v uv &> /dev/null; then
    pipx install uv --force
fi

python3 -m venv "${tools_dir}/.venv"
source "${tools_dir}/.venv/bin/activate"
pip3 install py2neo pandas prettytable neo4j tabulate argcomplete alive-progress "numpy<1.29.0" colorama requests termcolor toml --upgrade
deactivate

echo "Downloading bloodhound-cli..."
wget https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz -O "${tools_dir}"/bloodhound-cli-linux-amd64.tar.gz
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download bloodhound-cli"
    exit 1
fi

tar -xvzf "${tools_dir}"/bloodhound-cli-linux-amd64.tar.gz -C "${tools_dir}"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract bloodhound-cli"
    exit 1
fi
chmod +x "${tools_dir}"/bloodhound-cli

echo "Installing AD_Miner..."
uv tool install git+https://github.com/Mazars-Tech/AD_Miner --force
echo "Downloading PlumHound..."
wget https://github.com/PlumHound/PlumHound/archive/refs/heads/master.zip -O "${tools_dir}"/PlumHound.zip
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to download PlumHound (analysis will skip PlumHound)"
fi
if [ -f "${tools_dir}"/PlumHound.zip ]; then
    unzip -o "${tools_dir}"/PlumHound.zip -d "${tools_dir}"
    if [ $? -ne 0 ]; then
        echo "WARNING: Failed to extract PlumHound (analysis will skip PlumHound)"
    fi
fi
echo "Downloading analysis scripts..."
wget https://raw.githubusercontent.com/zeronetworks/BloodHound-Tools/main/Ransomulator/ransomulator.py -O "${tools_dir}"/ransomulator.py
wget https://raw.githubusercontent.com/kaluche/bloodhound-quickwin/main/bhqc.py -O "${tools_dir}"/bhqc.py
echo "Installing GoodHound..."
uv tool install git+https://github.com/idnahacks/GoodHound --force

echo "Cloning ad-recon..."
git clone https://github.com/c0ffee0wl/ad-recon "${tools_dir}"/ad-recon
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to clone ad-recon (analysis will skip ad-recon)"
fi

echo "Installing BloodHound.py..."
uv tool install git+https://github.com/dirkjanm/bloodhound.py --force
uv tool install "git+https://github.com/dirkjanm/BloodHound.py@bloodhound-ce" --force --with bloodhound-ce

echo ""
echo "Installation complete!"

#!/bin/bash

tools_dir="/opt/BA_tools"
sudo mkdir "${tools_dir}" 2>/dev/null
sudo chown -R "$(whoami)":"$(whoami)" "${tools_dir}"

sudo apt-get update

# Install docker-ce
if ! dpkg -l docker-ce &> /dev/null; then

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg || true; done

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    DOCKER_CODENAME="bookworm"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $DOCKER_CODENAME stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo systemctl enable docker --now
    echo "Adding current user to docker group..."
    sudo usermod -aG docker $USER
    echo "NOTE: You need to log out and log back in for docker group membership to take effect"
    echo "      Or run: newgrp docker"
fi

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
git clone https://github.com/tid35/ad-recon "${tools_dir}"/ad-recon
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to clone ad-recon (analysis will skip ad-recon)"
fi

echo "Installing BloodHound.py..."
uv tool install git+https://github.com/dirkjanm/bloodhound.py --force
uv tool install "git+https://github.com/dirkjanm/BloodHound.py@bloodhound-ce" --force --with bloodhound-ce

echo ""
echo "Installation complete!"

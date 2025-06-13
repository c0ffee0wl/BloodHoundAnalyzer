
# BloodHoundAnalyzer

## Overview

BloodHoundAnalyzer is a bash script designed to automate the collection, deployment, import, and analysis of BloodHound, an Active Directory (AD) security tool. This script facilitates the collection of BloodHound data, setup and teardown of a BloodHound instance, import of data, and running various analysis tools on the collected data.

## Prerequisites

Before using BloodHoundAnalyzer, ensure you have the following tools installed:

- python3
- docker-ce (for BloodHoundCE version), see [Docker CE Documentation](https://docs.docker.com/engine/install/)
- neo4j (for old BloodHound version)

Run the `install.sh` script to install the following tools:
  - **bloodhound-python**: Collects Active Directory data.
  - **bloodhound-automation**: Automates deployment of BloodHoundCE.
  - **AD-miner**: Runs analysis and generates an AD miner report.
  - **GoodHound**: Runs GoodHound analysis.
  - **Ransomulator**: Runs the ransomulator script.
  - **BloodHound QuickWin**: Runs the BloodHoundQuickWin script.
  - **PlumHound**: Runs PlumHound tasks and short path analyses.
  - **ad-recon**: Runs ad-recon pathing and transitive queries.

```bash
# Install Docker CE on Kali Linux
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
 echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list 
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker --now
sudo docker ps

# Install BloodHoundAnalyzer
sudo git clone --depth=1 https://github.com/c0ffee0wl/BloodHoundAnalyzer /opt/BloodHoundAnalyzer
sudo chown -R "$(whoami)":"$(whoami)" /opt/BloodHoundAnalyzer
cd /opt/BloodHoundAnalyzer && ./install.sh
```


## Usage

Run the script with one or more of the modules as detailed below. M
ake sure to have the necessary permissions to execute Docker or run Neo4j.

```bash
./BloodHoundAnalyzer.sh [OPTIONS]
```

## Quick Start for BloodHound CE

```bash
DOMAIN=domain.local

# Initialize environment and start containers
/opt/BloodHoundAnalyzer/BloodHoundAnalyzer.sh -M start -d $DOMAIN

# To view progress
tail -f /opt/BA_tools/bloodhound-automation/projects/$DOMAIN/logs.txt

# To upload AzureHound data, you have to zip the json
zip azurehound.zip azurehound.json

# Import
for file in *.zip; do /opt/BloodHoundAnalyzer/BloodHoundAnalyzer.sh -M import -d $DOMAIN --data "$file"; done

# Analyze
mkdir analyzer_output
/opt/BloodHoundAnalyzer/BloodHoundAnalyzer.sh -M analyze -d $DOMAIN -o $PWD/analyzer_output

# Stop containers
/opt/BloodHoundAnalyzer/BloodHoundAnalyzer.sh -M stop -d $DOMAIN

# Finally, to delete
/opt/BloodHoundAnalyzer/BloodHoundAnalyzer.sh -M clean -d $DOMAIN
```

### Options

- `-d, --domain DOMAIN`  
  Specify the AD domain to analyze (required for BloodHoundCE and for Collection).

- `-u, --username`  
  Username (required for Collection only).

- `-p, --password`  
  Password - NTLM authentication (required for Collection only).

- `-H, --hash`  
  LM:NT - NTLM authentication (alternative to password, used for Collection only).

- `-K, --kerb`  
  Location to Kerberos ticket './krb5cc_ticket' - Kerberos authentication (alternative to password, used for Collection only).

- `-A, --aes`  
  AES Key - Kerberos authentication (alternative to password, used for Collection only).

- `--dc`  
  IP Address of Target Domain Controller (required for Collection only).

- `-o, --output OUTPUT_DIR`  
  Specify the directory where analysis results will be saved. Defaults to the current directory.

- `-D, --data DATA_PATH`  
  Specify the path to the BloodHound ZIP file to import.

- `-M, --modules MODULES`  
  Comma separated modules to execute between:  
    - **collect:** Run bloodHound-python to collect Active Directory data.  
    - **list** : List available projects (only for BloodHoundCE).  
    - **start** : Start BloodHoundCE containers or neo4j.  
    - **run** : Run BloodHound GUI or Firefox with BloodHoundCE webpage.  
    - **import** : Import BloodHound data into the neo4j database.  
    - **analyze** : Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on the imported data.  
    - **stop** : Stop BloodHoundCE containers or neo4j.  
    - **clean** : Stop and delete BloodHoundCE containers (only for BloodHoundCE).  

- `--old`  
  Use the old version of BloodHound.

- `--oldpass`  
  Specify Neo4j password for the old version of BloodHound.

- `-h, --help`  
  Display the help message.

## Examples

### Collect Active Directory data (requires credentials and access to AD environment)

```bash
./BloodHoundAnalyzer.sh -M collect -d example.com -u user -p password
```

### List deployed BloodHoundCE projects

```bash
./BloodHoundAnalyzer.sh -M list
```

### Start BloodHoundCE containers or old BloodHound's Neo4j

```bash
./BloodHoundAnalyzer.sh -M start -d example.com
./BloodHoundAnalyzer.sh -M start --old
```

### Open Firefox with BloodHoundCE web page or run old BloodHound GUI
```bash
./BloodHoundAnalyzer.sh -M run
./BloodHoundAnalyzer.sh -M run --old
```

### Import Data, and Run Analysis

```bash
./BloodHoundAnalyzer.sh -M import,analyze -d example.com --data /path/to/bloodhound/data.zip -o /path/to/output
./BloodHoundAnalyzer.sh -M import,analyze --data /path/to/bloodhound/data.zip --old --oldpass bloodhound -o /path/to/output
```

### Run Analysis on previously imported data

```bash
./BloodHoundAnalyzer.sh -M analyze -d example.com -o /path/to/output
./BloodHoundAnalyzer.sh -M analyze --old --oldpass bloodhound -o /path/to/output
```

### Stop BloodHoundCE containers or old BloodHound's Neo4j 

```bash
./BloodHoundAnalyzer.sh -M stop -d example.com
./BloodHoundAnalyzer.sh -M stop --old
```

### Clean up BloodHoundCE Containers

```bash
./BloodHoundAnalyzer.sh -M clean -d example.com
```

## License

This project is licensed under the terms of the MIT license. 

## Acknowledgments
BloodHoundAnalyzer uses the following tools:
- https://github.com/dirkjanm/BloodHound.py
- https://github.com/Tanguy-Boisset/bloodhound-automation
- https://github.com/Mazars-Tech/AD_Miner
- https://github.com/PlumHound/PlumHound
- https://github.com/idnahacks/GoodHound
- https://github.com/zeronetworks/BloodHound-Tools/blob/main/Ransomulator
- https://github.com/kaluche/bloodhound-quickwin
- https://github.com/tid35/ad-recon

#!/bin/bash

# Global variables
VENVS_PATH="/opt/venvs"
VERBOSE=false
OUTPUT="/dev/null" # quiet mode by default

# Get 3rd party tools in /opt
sudo chown $USER:$USER /opt

install_base_baseline_tools(){
  echo "[$(date +%H:%M:%S)]: Installing baseline tools"
  sudo apt-get update > $OUTPUT
  sudo apt-get install -y nala > $OUTPUT
  sudo nala install -y python3 python3.10-venv python3-pip libpython3.10-dev python2 python2-dev libpython2.7-dev binwalk exiftool csvkit tree curl git wget build-essential libssl-dev unrar nmap whois p7zip-full sqlitebrowser ruby-dev pngtools pngcheck yara ltrace btop htop qemu-utils jq fq sqlite3 ghex cmake pkg-config libsecret-1-dev clamav ffmpeg fdisk testdisk extundelete bat fonts-powerline > $OUTPUT
}

install_base_python_environments(){
  # Setup python environments (python 2 & 3 needed to run all forensic tools)
  echo "[$(date +%H:%M:%S)]: Setting up Python 2 & 3 environments"
  TARGET_LINK="/usr/bin/python"
  SOURCE_LINK="/usr/bin/python3"
  echo "[$(date +%H:%M:%S)]: Testing Python3 symbolic link"
  if [ -L "$TARGET_LINK" ]; then
    echo "[$(date +%H:%M:%S)]: Symbolic link '$TARGET_LINK' already exists. Skipping..."
  else
    echo "[$(date +%H:%M:%S)]: Symbolic link '$TARGET_LINK' doesn't exists. Setting up..."
    sudo ln -s "$SOURCE_LINK" "$TARGET_LINK"
    
    # Check the exit status of the ln command
    if [ $? -eq 0 ]; then
      echo "[$(date +%H:%M:%S)]: Symbolic link created successfully: $TARGET_LINK -> $SOURCE_LINK"
    else
      echo "[$(date +%H:%M:%S)]: Failed to create symbolic link: $TARGET_LINK. Check for errors."
    fi
  fi
  mkdir -p $VENVS_PATH
  curl -s https://bootstrap.pypa.io/pip/2.7/get-pip.py --output /tmp/get-pip.py
  sudo python2 /tmp/get-pip.py > $OUTPUT 2> $OUTPUT
  rm /tmp/get-pip.py
  python2 -m pip install virtualenv --no-warn-script-location > $OUTPUT 2> $OUTPUT
  python3 -m pip install virtualenv --no-warn-script-location > $OUTPUT
}

install_base_rust(){
  echo "Setting up Rust environment"
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
}

install_base_zsh(){
  echo "Setting up zsh and oh-my-zsh"
  sudo apt-get install -qq -y zsh
  OH_MY_ZSH_FOLDER="$HOME/.oh-my-zsh"
  echo "Checking if the oh-my-zsh folder already exists..."
  if [ -d "$OH_MY_ZSH_FOLDER" ]; then
    echo "The '$OH_MY_ZSH_FOLDER' folder already exists. Skipping the installation of oh-my-zsh..."
  else
    echo "The '$OH_MY_ZSH_FOLDER' folder does not exist. Proceeding with the installation of oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="steeef"/g' ~/.zshrc
}

install_optional_terminator(){
  echo "Setting up Terminator"
  sudo apt-get install -qq -y terminator
  sudo mkdir -p /etc/xdg/terminator
  sudo sh -c "cat >> /etc/xdg/terminator/config" <<-EOF
  [global_config]
    suppress_multiple_term_dialog = True
  [keybindings]
    new_tab = <Primary>t
    split_horiz = F1
    split_vert = F2
    close_term = F3
    paste = <Primary>v
    close_window = None
    help = None
  [profiles]
    [[default]]
      background_darkness = 0.95
      background_type = transparent
      cursor_color = "#aaaaaa"
      foreground_color = "#00ff00"
      scrollback_infinite = True
      split_to_group = True
  [layouts]
    [[default]]
      [[[window0]]]
        type = Window
        parent = ""
      [[[child1]]]
        type = Terminal
        parent = window0
  [plugins]
EOF
}

install_optional_sublime_text(){
  echo "Setting up Sublime Text"
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  sudo nala update -qq
  sudo apt-get install -qq -y sublime-text
}

install_steg_stegoveritas(){
  echo "Setting up Stegoveritas"
  {
    sudo python3 -m pip install stegoveritas
    stegoveritas_install_deps
    # => TODO: fix error messages
  } 2> /dev/null
}

install_steg_stegseek(){
  echo "Setting up Stegseek"
  sudo apt-get install -qq -y libjpeg62
  cd /tmp
  wget https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb
  sudo dpkg -i stegseek_0.6-1.deb
}

install_steg_zsteg(){
  echo "Setting up Zsteg"
  sudo gem install rake
  sudo gem install zsteg
}

install_tools_category(){
  prefix=$1
  functions_with_prefix=$(declare -F | awk -v prefix="$prefix" '$3 ~ "^" prefix { print $3 }')
  
  # Iterate over each function with the prefix and execute it
  for func in $functions_with_prefix; do
    $func
  done
}

install_everything(){
  install_base_baseline_tools
  install_base_python_environments
  #install_base_rust
  #install_base_zsh
  #install_optional_terminator
  #install_optional_sublime_text
  #install_tools_category "install_steg_"
}

display_help(){
  echo "Usage: $0 [OPTION]"
  echo "Install tools for forensic analysis environment."
  echo
  echo "Options:"
  echo "  -h, --help         Display this help and exit"
  echo "  -v, --verbose      Enable verbose mode (disabled by default)"
  echo "  -a, --all          Install all tools"
  echo "  --steg             Install all steganography tools"
  echo
  echo "Example commands:"
  echo "  Install all tools:                    $0 -a"
  echo "  Install all tools with verbose mode:  $0 -a -v"
  echo "  Install Steganography tools:          $0 --steg"
}

main(){
  if [[ $# -eq 0 ]]; then
    display_help
    exit 0
  fi

  for arg in "$@"; do
    case $arg in
      -v|--verbose)
        OUTPUT="/dev/stdout"
        ;;
    esac
  done

  for arg in "$@"; do
    case $arg in
      -h|--help)
        display_help
        exit 0
        ;;
      -a|--all)
        install_everything
        exit 0
        ;;
      --steg)
        install_tools_category "install_base_"
        install_tools_category "install_steg_"
        exit 0
        ;;
      -v)
        # skip the invalid option error
        ;;
      *)
        echo "Invalid option: $arg. Use -h or --help for usage information." >&2
        exit 1
        ;;
    esac
  done
}

main "$@"

exit 0
































































##################################################
# Containers tools
##################################################
# Container Explorer
cd /tmp
wget https://raw.githubusercontent.com/google/container-explorer/main/script/setup.sh
sudo bash setup.sh install

# Docker explorer
python3 -m virtualenv ~/venvs/docker-explorer
source ~/venvs/docker-explorer/bin/activate
python3 -m pip install docker-explorer
deactivate

##################################################
# LNK tools
##################################################
# LnkParse3
sudo python3 -m pip install LnkParse3

##################################################
# RDP tools
##################################################
TOOL_PATH="/opt/RDP_tools"
mkdir -p $TOOL_PATH

# BMC tools
TARGET_FOLDER="$TOOL_PATH/bmc-tools"
if [ -d "$TARGET_FOLDER" ]; then
  echo "Tool '$TARGET_FOLDER' already exists. Updating..."
  cd $TARGET_FOLDER
  git pull
else
  cd $TOOL_PATH
  git clone https://github.com/ANSSI-FR/bmc-tools
fi

# rdpieces
cd /opt
git clone https://github.com/brimorlabs/rdpieces
sudo apt-get install -y libio-all-perl libdatetime-perl libdbd-sqlite3-perl

##################################################
# Network tools
##################################################
# Wireshark
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark
# Wireshark profiles
# git clone the repo and put all profiles folder into ~/.config/wireshark/profiles
# https://github.com/Dysnome/Wireshark-Profiles

# NetFlow
## RITA
#cd /tmp
#wget https://github.com/activecm/rita/releases/download/v4.8.0/install.sh
#chmod +x install.sh
#sudo ./install.sh

##################################################
# Email tools
##################################################
# mpack: munpack
sudo apt-get install -y mpack libemail-outlook-message-perl

# pff-tools: pffexport
sudo apt-get install -y pff-tools

# thunderbird => As of 2023-22-19, doesn't work pretty well on WSL
sudo apt-get install -y thunderbird adwaita-icon-theme-full

##################################################
# EVTX tools
##################################################
mkdir /opt/EVTX_tools

# Chainsaw
cd /opt/EVTX_tools
git clone https://github.com/WithSecureLabs/chainsaw.git
git clone https://github.com/sbousseaden/EVTX-ATTACK-SAMPLES.git
cd chainsaw
cargo build --release

# Sigma
cd /opt/EVTX_tools
git clone https://github.com/SigmaHQ/sigma

# Hayabusa
cd /opt/EVTX_tools
git clone https://github.com/Yamato-Security/hayabusa --recursive
cd hayabusa
cargo build --release


##################################################
# PDF tools
##################################################
mkdir /opt/pdf

# poppler-utils: pdfinfo, pdfsig, pdftotext, etc
sudo apt-get install -y poppler-utils

# peepdf
cd /opt/pdf
git clone https://github.com/jesparza/peepdf
chmod +x peepdf/*.py

# pdfplumber
cd /opt/pdf
git clone https://github.com/jsvine/pdfplumber
sudo python3 pdfplumber/setup.py install

##################################################
# Password cracking
##################################################
# John the Ripper
cd /opt
git clone https://github.com/openwall/john
cd john/src
cpu_count=$(nproc)
half_cpu=$((cpu_count / 2))
./configure && make -j $half_cpu

##################################################
# Didier Stevens tools
##################################################
cd /opt
git clone https://github.com/DidierStevens/DidierStevensSuite
chmod +x DidierStevensSuite/*.py

##################################################
# Memory analysis
##################################################
# Volatility 2
cd /opt
git clone https://github.com/volatilityfoundation/volatility volatility2
python2 -m virtualenv ~/venvs/volatility2
source ~/venvs/volatility2/bin/activate
cd /opt/volatility2
python2 setup.py install
deactivate

# Volatility 2 dependencies
source ~/venvs/volatility2/bin/activate
pip install --upgrade setuptools
pip2 install pycrypto && pip install distorm3
deactivate

# Volatility 3
cd /opt
git clone https://github.com/volatilityfoundation/volatility3
python3 -m virtualenv ~/venvs/volatility3

# Volatility 3 dependencies
source ~/venvs/volatility3/bin/activate
pip install yara-python
pip install pefile
pip install pycryptodome
deactivate

##################################################
# NTFS analysis
##################################################
cd /opt
git clone https://github.com/dkovar/analyzeMFT


##################################################
# Add 3rd party tools to PATH + some setups
##################################################
cat <<EOT >> ~/.zshrc
path+=('$HOME/.local/bin')
path+=('/opt/DidierStevensSuite/')
path+=('/opt/john/run/')
path+=('/opt/bmc-tools/')
path+=('/opt/rdpieces/')
path+=('/opt/WMI_Forensics')
path+=('/opt/container-explorer/bin/')
path+=('$HOME/.cargo/bin/')
path+=('/opt/analyzeMFT')
# ADD CHAINSAW
# ADD HAYABUSA

alias peepdf="python2 /opt/peepdf/peepdf.py \$@"
alias john="/opt/john/run/john"
alias ll="ls -al"
alias vol=vol3
alias rdpieces="perl /opt/rdpieces/rdpieces.pl \$@"
alias PyWMIPersistenceFinder="python2 /opt/WMI_Forensics/PyWMIPersistenceFinder.py \$@"
alias cat=/usr/bin/batcat

SAVEHIST=1000000
HISTSIZE=1000000

function vol3(){
   source ~/venvs/volatility3/bin/activate
   python3 /opt/volatility3/vol.py \$@
   deactivate
}

function vol2(){
   source ~/venvs/volatility2/bin/activate
   python2 /opt/volatility2/vol.py \$@
   deactivate
}

function docker-explorer(){
  source ~/venvs/docker-explorer/bin/activate
  de.py \$@
  deactivate
}
EOT

# Switch shell
printf "Change default shell to Zsh. Please enter your password to confirm the change.\n"
chsh -s /bin/zsh
zsh
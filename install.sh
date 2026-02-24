#!/bin/bash

# GitHub Automation Pro Beta Installer
# Version: 1.0.0-beta
# Date: 2026-02-24

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="GitHub Automation Pro"
APP_VERSION="1.0.0-beta"
INSTALL_DIR="$HOME/.github-automation-pro"
CONFIG_DIR="$HOME/.config/github-automation-pro"
LOG_DIR="$HOME/.local/share/github-automation-pro/logs"
BIN_DIR="$HOME/.local/bin"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $APP_NAME Beta Installer${NC}"
    echo -e "${BLUE}  Version: $APP_VERSION${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_dependencies() {
    print_info "Checking system dependencies..."
    
    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        print_success "Python $PYTHON_VERSION found"
    else
        print_error "Python 3 not found. Please install Python 3.8 or higher."
        exit 1
    fi
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        print_success "pip3 found"
    else
        print_warning "pip3 not found. Attempting to install..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y python3-pip
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python3
        fi
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_success "Git found"
    else
        print_error "Git not found. Please install Git."
        exit 1
    fi
    
    # Check Node.js (optional)
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js $NODE_VERSION found"
    else
        print_warning "Node.js not found (optional for web interface)"
    fi
}

create_directories() {
    print_info "Creating installation directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BIN_DIR"
    
    print_success "Directories created"
}

install_python_dependencies() {
    print_info "Installing Python dependencies..."
    
    # Create requirements.txt
    cat > "$INSTALL_DIR/requirements.txt" << 'EOF'
requests>=2.28.0
python-telegram-bot>=20.0
sqlite3
python-dotenv>=1.0.0
schedule>=1.2.0
colorama>=0.4.6
pyyaml>=6.0
EOF
    
    pip3 install -r "$INSTALL_DIR/requirements.txt"
    print_success "Python dependencies installed"
}

copy_files() {
    print_info "Copying application files..."
    
    # Copy core files from current directory
    cp -r /home/zjc92/.openclaw/workspace/*.py "$INSTALL_DIR/"
    cp -r /home/zjc92/.openclaw/workspace/*.json "$INSTALL_DIR/"
    cp -r /home/zjc92/.openclaw/workspace/*.md "$INSTALL_DIR/" 2>/dev/null || true
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR"/*.py 2>/dev/null || true
    
    print_success "Application files copied"
}

create_config() {
    print_info "Creating configuration file..."
    
    # Ask for beta access code
    echo ""
    echo -e "${YELLOW}Please enter your beta access code:${NC}"
    read -p "Access Code: " ACCESS_CODE
    
    if [[ "$ACCESS_CODE" != "BETA2026" ]]; then
        print_error "Invalid access code. Please contact beta-support@jet-automation.dev"
        exit 1
    fi
    
    # Create default config
    cat > "$CONFIG_DIR/config.yaml" << EOF
# GitHub Automation Pro Configuration
# Beta Version: $APP_VERSION

app:
  name: "$APP_NAME"
  version: "$APP_VERSION"
  mode: "beta"
  access_code: "$ACCESS_CODE"

github:
  # Your GitHub Personal Access Token
  # Create at: https://github.com/settings/tokens
  # Required scopes: repo, read:org, read:user
  token: ""
  
  # Repositories to monitor
  repositories:
    - "openclaw/openclaw"
    - "facebook/react"
    - "microsoft/vscode"
  
  # Update interval in seconds
  check_interval: 1800  # 30 minutes

telegram:
  # Telegram Bot Token (optional)
  # Create bot via @BotFather on Telegram
  bot_token: ""
  
  # Your Telegram Chat ID
  # Get from @userinfobot on Telegram
  chat_id: ""
  
  # Enable notifications
  enabled: false

database:
  path: "$CONFIG_DIR/github_automation.db"

logging:
  level: "INFO"
  file: "$LOG_DIR/app.log"
  max_size_mb: 10
  backup_count: 5

monetization:
  enabled: true
  min_bounty_amount: 10
  currency: "USD"
  
  # MoltsPay configuration (optional)
  moltspay:
    enabled: false
    wallet_address: ""
    network: "base"

beta:
  feedback_url: "https://forms.jet-automation.dev/beta-feedback"
  support_email: "beta-support@jet-automation.dev"
  discord_url: "https://discord.gg/jet-automation"
EOF
    
    print_success "Configuration file created at $CONFIG_DIR/config.yaml"
}

create_start_script() {
    print_info "Creating startup script..."
    
    cat > "$BIN_DIR/github-automation-pro" << 'EOF'
#!/bin/bash

# GitHub Automation Pro Startup Script
INSTALL_DIR="$HOME/.github-automation-pro"
CONFIG_DIR="$HOME/.config/github-automation-pro"
LOG_DIR="$HOME/.local/share/github-automation-pro/logs"

cd "$INSTALL_DIR"

case "$1" in
    start)
        echo "🚀 Starting GitHub Automation Pro..."
        python3 github-reporter.py
        ;;
    stop)
        echo "🛑 Stopping GitHub Automation Pro..."
        pkill -f "github-reporter.py" || true
        ;;
    status)
        echo "📊 GitHub Automation Pro Status:"
        if pgrep -f "github-reporter.py" > /dev/null; then
            echo "✅ Running"
        else
            echo "❌ Stopped"
        fi
        ;;
    config)
        echo "⚙️  Opening configuration directory..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$CONFIG_DIR"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open "$CONFIG_DIR" || nautilus "$CONFIG_DIR" || thunar "$CONFIG_DIR"
        else
            echo "Config directory: $CONFIG_DIR"
        fi
        ;;
    logs)
        echo "📝 Showing logs..."
        tail -f "$LOG_DIR/app.log"
        ;;
    update)
        echo "🔄 Updating GitHub Automation Pro..."
        cd "$INSTALL_DIR"
        git pull origin beta
        pip3 install -r requirements.txt --upgrade
        echo "✅ Update complete"
        ;;
    *)
        echo "Usage: github-automation-pro {start|stop|status|config|logs|update}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the automation service"
        echo "  stop     - Stop the automation service"
        echo "  status   - Check if service is running"
        echo "  config   - Open configuration directory"
        echo "  logs     - View application logs"
        echo "  update   - Update to latest version"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$BIN_DIR/github-automation-pro"
    print_success "Startup script created"
}

setup_cron_job() {
    print_info "Setting up automatic monitoring..."
    
    CRON_JOB="*/30 * * * * cd $INSTALL_DIR && python3 github-reporter.py >> $LOG_DIR/cron.log 2>&1"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "github-reporter.py"; echo "$CRON_JOB") | crontab -
    
    print_success "Cron job configured (runs every 30 minutes)"
}

post_install() {
    print_info "Finalizing installation..."
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc" 2>/dev/null || true
        print_warning "Added $BIN_DIR to PATH. Please restart your shell or run: source ~/.bashrc"
    fi
    
    # Create desktop entry (Linux)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        mkdir -p "$HOME/.local/share/applications"
        cat > "$HOME/.local/share/applications/github-automation-pro.desktop" << EOF
[Desktop Entry]
Name=GitHub Automation Pro
Comment=Automate GitHub income opportunities
Exec=$BIN_DIR/github-automation-pro start
Icon=$INSTALL_DIR/icon.png
Terminal=true
Type=Application
Categories=Development;
EOF
    fi
    
    print_success "Installation complete!"
}

show_next_steps() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "🎉 $APP_NAME has been installed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Configure your settings:"
    echo "      $CONFIG_DIR/config.yaml"
    echo ""
    echo "   2. Get your GitHub Personal Access Token:"
    echo "      https://github.com/settings/tokens"
    echo "      Required scopes: repo, read:org, read:user"
    echo ""
    echo "   3. Start the application:"
    echo "      github-automation-pro start"
    echo ""
    echo "   4. Check status:"
    echo "      github-automation-pro status"
    echo ""
    echo "   5. View logs:"
    echo "      github-automation-pro logs"
    echo ""
    echo "📞 Support:"
    echo "   • Email: beta-support@jet-automation.dev"
    echo "   • Discord: https://discord.gg/jet-automation"
    echo "   • Documentation: https://docs.jet-automation.dev/beta"
    echo ""
    echo "⚠️  Remember: This is beta software. Please report any issues!"
    echo ""
}

# Main installation process
main() {
    print_header
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root/sudo. Run as normal user."
        exit 1
    fi
    
    # Check if already installed
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "$APP_NAME seems to be already installed."
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        print_info "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Run installation steps
    check_dependencies
    create_directories
    install_python_dependencies
    copy_files
    create_config
    create_start_script
    setup_cron_job
    post_install
    show_next_steps
}

# Run main function
main "$@"
#!/bin/bash
#
# Silicon Compatibility Scanner
# A diagnostic tool that identifies Apple Silicon compatibility issues for developers
# migrating from Windows/x86.
#

# =========================================================
# CONFIGURATION
# =========================================================

# Define color codes for output formatting
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Script version
readonly VERSION="1.0.0"

# Report file path
REPORT_FILE="silicon_compatibility_report_$(date +%Y%m%d_%H%M%S).md"

# Flags
TEST_MODE=false
VERBOSE=false

# Counters for issues found
CRITICAL_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

# =========================================================
# HELPER FUNCTIONS
# =========================================================

# Print a message with color
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# Print a section header
print_header() {
    local message="$1"
    echo
    echo -e "${BOLD}${BLUE}=== ${message} ===${RESET}"
    echo
}

# Print verbose message only if verbose mode is enabled
print_verbose() {
    local message="$1"
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${RESET} ${message}"
    fi
}

# Log an issue with severity level
log_issue() {
    local severity="$1"
    local message="$2"
    local solution="$3"
    
    case "$severity" in
        "CRITICAL")
            print_message "${RED}[CRITICAL]${RESET}" "${message}"
            CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
            ;;
        "WARNING")
            print_message "${YELLOW}[WARNING]${RESET}" "${message}"
            WARNING_COUNT=$((WARNING_COUNT + 1))
            ;;
        "INFO")
            print_message "${GREEN}[INFO]${RESET}" "${message}"
            INFO_COUNT=$((INFO_COUNT + 1))
            ;;
    esac
    
    if [ -n "$solution" ]; then
        echo -e "   ${BOLD}Solution:${RESET} ${solution}"
    fi
    
    # Add to report file
    echo "- **${severity}:** ${message}" >> "$REPORT_FILE"
    if [ -n "$solution" ]; then
        echo "  - Solution: ${solution}" >> "$REPORT_FILE"
    fi
    echo >> "$REPORT_FILE"
}

# Check if running in test mode
is_test_mode() {
    if [ "$TEST_MODE" = true ]; then
        return 0
    else
        return 1
    fi
}

# Run a command with test mode awareness
run_command() {
    local command="$1"
    
    if is_test_mode; then
        echo "[TEST MODE] Would run: $command"
        return 0
    else
        if [ "$VERBOSE" = true ]; then
            echo -e "${BLUE}[RUNNING]${RESET} $command"
        fi
        eval "$command"
        return $?
    fi
}

# Check if binary exists and determine its architecture
check_binary_arch() {
    local binary_path="$1"
    
    # Check if binary exists
    if [ ! -f "$binary_path" ]; then
        print_verbose "Binary not found: $binary_path"
        return 1
    fi
    
    # Use file command to determine architecture
    local file_output
    file_output=$(file "$binary_path" 2>/dev/null)
    
    if [[ "$file_output" == *"Mach-O 64-bit executable arm64"* ]]; then
        echo "arm64"
        return 0
    elif [[ "$file_output" == *"Mach-O 64-bit executable x86_64"* ]]; then
        echo "x86_64"
        return 0
    elif [[ "$file_output" == *"Mach-O universal binary"* ]]; then
        if [[ "$file_output" == *"arm64"* ]]; then
            echo "universal (includes arm64)"
            return 0
        else
            echo "universal (x86_64 only)"
            return 0
        fi
    else
        echo "unknown"
        return 1
    fi
}

# =========================================================
# SYSTEM DETECTION FUNCTIONS
# =========================================================

# Detect system architecture
detect_architecture() {
    print_header "Detecting System Architecture"
    
    # Check if running on Apple Silicon
    if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ]; then
        print_message "$GREEN" "✓ System is running on Apple Silicon"
        IS_APPLE_SILICON=true
    else
        print_message "$YELLOW" "⚠ System is not running on Apple Silicon (Intel-based Mac)"
        IS_APPLE_SILICON=false
    fi
    
    # Check current architecture
    CURRENT_ARCH=$(uname -m)
    print_message "$BLUE" "Current architecture: $CURRENT_ARCH"
    
    # Check chip model
    CHIP_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    print_message "$BLUE" "Processor: $CHIP_MODEL"
    
    # Check Rosetta 2 status
    if [ "$IS_APPLE_SILICON" = true ]; then
        if [ -f "/Library/Apple/usr/libexec/oah/libRosettaRuntime" ]; then
            print_message "$GREEN" "✓ Rosetta 2 is installed"
            ROSETTA_INSTALLED=true
        else
            print_message "$YELLOW" "⚠ Rosetta 2 is not installed"
            ROSETTA_INSTALLED=false
            log_issue "WARNING" "Rosetta 2 is not installed, which may cause issues with Intel-based applications" \
                     "Install Rosetta 2 by running: softwareupdate --install-rosetta"
        fi
    fi
    
    # Check macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    print_message "$BLUE" "macOS version: $MACOS_VERSION"
    
    # Check if macOS version is compatible with Apple Silicon
    if [ "$(echo "$MACOS_VERSION" | cut -d. -f1)" -lt 11 ]; then
        log_issue "CRITICAL" "macOS version $MACOS_VERSION is not compatible with Apple Silicon" \
                 "Upgrade to macOS 11 (Big Sur) or newer"
    fi
    
    # Check if system is running in native mode
    if [ "$IS_APPLE_SILICON" = true ] && [ "$CURRENT_ARCH" != "arm64" ]; then
        log_issue "CRITICAL" "System is Apple Silicon but running in x86_64 mode" \
                 "Restart Terminal in native ARM64 mode"
    fi
    
    # Add architecture information to report
    echo "## System Information" >> "$REPORT_FILE"
    echo "- **Processor Type:** $CHIP_MODEL" >> "$REPORT_FILE"
    echo "- **Architecture:** $CURRENT_ARCH" >> "$REPORT_FILE"
    echo "- **macOS Version:** $MACOS_VERSION" >> "$REPORT_FILE"
    echo "- **Apple Silicon:** $([ "$IS_APPLE_SILICON" = true ] && echo "Yes" || echo "No")" >> "$REPORT_FILE"
    echo "- **Rosetta 2:** $([ "$ROSETTA_INSTALLED" = true ] && echo "Installed" || echo "Not installed")" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
}

# =========================================================
# DEVELOPER ENVIRONMENT FUNCTIONS
# =========================================================

# Check package managers
check_package_managers() {
    print_header "Checking Package Managers"
    
    # Create package managers section in report
    echo "## Package Managers" >> "$REPORT_FILE"
    
    # Check Homebrew
    if command -v brew >/dev/null 2>&1; then
        HOMEBREW_PREFIX=$(brew --prefix)
        print_message "$GREEN" "✓ Homebrew is installed at: $HOMEBREW_PREFIX"
        
        # Check if Homebrew is installed in the correct location for the architecture
        if [ "$IS_APPLE_SILICON" = true ] && [ "$HOMEBREW_PREFIX" = "/usr/local" ]; then
            log_issue "WARNING" "Homebrew is installed in the Intel location (/usr/local) instead of the Apple Silicon location (/opt/homebrew)" \
                     "Consider reinstalling Homebrew for Apple Silicon: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        elif [ "$IS_APPLE_SILICON" = false ] && [ "$HOMEBREW_PREFIX" = "/opt/homebrew" ]; then
            log_issue "WARNING" "Homebrew is installed in the Apple Silicon location (/opt/homebrew) on an Intel Mac" \
                     "This is unusual. Consider reinstalling Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        fi
        
        # Check Homebrew packages with native alternatives
        print_verbose "Checking Homebrew packages architecture..."
        echo "### Homebrew Packages" >> "$REPORT_FILE"
        
        # Get list of installed packages
        if is_test_mode; then
            echo "[TEST MODE] Would check Homebrew packages"
        else
            local brew_list
            brew_list=$(brew list --formula 2>/dev/null)
            
            for package in $brew_list; do
                # Get package info
                local bin_path
                bin_path=$(which "$package" 2>/dev/null)
                
                if [ -n "$bin_path" ]; then
                    local arch
                    arch=$(check_binary_arch "$bin_path")
                    
                    if [ "$IS_APPLE_SILICON" = true ] && [[ "$arch" == *"x86_64"* ]] && [[ "$arch" != *"universal"* ]]; then
                        log_issue "WARNING" "Package '$package' is Intel-only ($arch) and running through Rosetta 2" \
                                 "Try reinstalling with: brew reinstall $package"
                        echo "  - $package: $arch ($bin_path)" >> "$REPORT_FILE"
                    elif [ "$VERBOSE" = true ]; then
                        print_verbose "Package '$package' architecture: $arch"
                        echo "  - $package: $arch ($bin_path)" >> "$REPORT_FILE"
                    fi
                fi
            done
        fi
    else
        print_message "$YELLOW" "⚠ Homebrew is not installed"
        echo "- Homebrew: Not installed" >> "$REPORT_FILE"
    fi
    
    echo >> "$REPORT_FILE"
    
    # Check Node.js and npm
    if command -v node >/dev/null 2>&1; then
        local node_path
        local node_arch
        local node_version
        
        node_path=$(which node)
        node_arch=$(check_binary_arch "$node_path")
        node_version=$(node --version 2>/dev/null)
        
        print_message "$GREEN" "✓ Node.js $node_version is installed ($node_arch)"
        echo "### Node.js" >> "$REPORT_FILE"
        echo "- **Version:** $node_version" >> "$REPORT_FILE"
        echo "- **Architecture:** $node_arch" >> "$REPORT_FILE"
        
        if [ "$IS_APPLE_SILICON" = true ] && [[ "$node_arch" == *"x86_64"* ]] && [[ "$node_arch" != *"universal"* ]]; then
            log_issue "WARNING" "Node.js is running under Rosetta 2 ($node_arch)" \
                     "Consider installing the ARM64 version: https://nodejs.org/"
        fi
        
        # Check for native modules in Node.js projects
        if command -v npm >/dev/null 2>&1 && [ "$IS_APPLE_SILICON" = true ]; then
            print_verbose "Checking for Node.js native modules..."
            
            # Look for package.json files in common locations
            local package_json_files
            if is_test_mode; then
                echo "[TEST MODE] Would search for package.json files"
            else
                # Only look in home directory and common project folders to avoid being too intrusive
                package_json_files=$(find "$HOME/Documents" "$HOME/Projects" "$HOME/repos" "$HOME/src" -name "package.json" -type f 2>/dev/null | head -n 10)
                
                if [ -n "$package_json_files" ]; then
                    echo "- **Native Module Check:** Found $(echo "$package_json_files" | wc -l | xargs) package.json files to check" >> "$REPORT_FILE"
                    
                    while IFS= read -r package_file; do
                        # Check if package.json contains native dependencies
                        if grep -q "\"dependencies\"\|\"devDependencies\"" "$package_file" 2>/dev/null; then
                            local project_dir
                            project_dir=$(dirname "$package_file")
                            local project_name
                            project_name=$(basename "$project_dir")
                            
                            print_verbose "Checking project: $project_name ($project_dir)"
                            
                            # Look for node_modules with native bindings 
                            if [ -d "$project_dir/node_modules" ]; then
                                local native_modules
                                native_modules=$(find "$project_dir/node_modules" -name "binding.gyp" -o -name "*.node" 2>/dev/null | head -n 5)
                                
                                if [ -n "$native_modules" ]; then
                                    log_issue "INFO" "Project '$project_name' contains native modules that might need recompilation for Apple Silicon" \
                                             "Run 'npm rebuild' in the project directory"
                                    echo "  - Project: $project_name contains native modules" >> "$REPORT_FILE"
                                fi
                            fi
                        fi
                    done <<< "$package_json_files"
                fi
            fi
        fi
    else
        print_message "$BLUE" "Node.js is not installed, skipping checks"
        echo "### Node.js: Not installed" >> "$REPORT_FILE"
    fi
    
    echo >> "$REPORT_FILE"
    
    # Check Python and pip
    if command -v python3 >/dev/null 2>&1; then
        local python_path
        local python_arch
        local python_version
        
        python_path=$(which python3)
        python_arch=$(check_binary_arch "$python_path")
        python_version=$(python3 --version 2>&1)
        
        print_message "$GREEN" "✓ $python_version is installed ($python_arch)"
        echo "### Python" >> "$REPORT_FILE"
        echo "- **Version:** $python_version" >> "$REPORT_FILE"
        echo "- **Architecture:** $python_arch" >> "$REPORT_FILE"
        
        if [ "$IS_APPLE_SILICON" = true ] && [[ "$python_arch" == *"x86_64"* ]] && [[ "$python_arch" != *"universal"* ]]; then
            log_issue "WARNING" "Python is running under Rosetta 2 ($python_arch)" \
                     "Consider installing the ARM64 version of Python"
        fi
        
        # Check pip packages with compiled extensions
        if command -v pip3 >/dev/null 2>&1; then
            print_verbose "Checking pip packages with compiled extensions..."
            echo "#### Pip Packages" >> "$REPORT_FILE"
            
            if is_test_mode; then
                echo "[TEST MODE] Would check pip packages"
            else
                # List of common packages that have native extensions
                local native_packages=("numpy" "scipy" "pandas" "matplotlib" "tensorflow" "torch" "opencv-python" "pillow")
                
                for package in "${native_packages[@]}"; do
                    if pip3 list 2>/dev/null | grep -q "$package"; then
                        local package_location
                        package_location=$(python3 -c "import importlib.util, $package; print(importlib.util.find_spec('$package').origin)" 2>/dev/null)
                        
                        if [ -n "$package_location" ]; then
                            print_verbose "Found $package at $package_location"
                            echo "  - $package: $package_location" >> "$REPORT_FILE"
                            
                            # Check if this is inside a Rosetta environment
                            if [ "$IS_APPLE_SILICON" = true ] && [[ "$python_arch" == *"x86_64"* ]]; then
                                log_issue "INFO" "Python package '$package' is installed in a Rosetta 2 environment" \
                                         "Consider reinstalling in a native ARM64 Python environment"
                            fi
                        fi
                    fi
                done
            fi
        fi
    else
        print_message "$BLUE" "Python 3 is not installed, skipping checks"
        echo "### Python: Not installed" >> "$REPORT_FILE"
    fi
    
    echo >> "$REPORT_FILE"
}

# Check processes running under Rosetta 2
check_rosetta_processes() {
    print_header "Checking Processes Running Under Rosetta 2"
    
    # Add Rosetta processes section to report
    echo "## Processes Running Under Rosetta 2" >> "$REPORT_FILE"
    
    if [ "$IS_APPLE_SILICON" = true ]; then
        echo "Checking for processes running under Rosetta 2 emulation..."
        
        if is_test_mode; then
            echo "[TEST MODE] Would check for Rosetta processes"
            return 0
        fi
        
        # Get list of running processes with architecture
        local processes
        processes=$(ps -A -o pid,command | grep -v "grep" | grep -v " ps -" | grep -v " PID " | grep -v "$REPORT_FILE")
        
        # Initialize counter for Rosetta processes
        local rosetta_count=0
        local critical_processes=()
        local dev_processes=()
        
        echo "### Active Processes Under Rosetta" >> "$REPORT_FILE"
        
        while IFS= read -r line; do
            local pid
            pid=$(echo "$line" | awk '{print $1}')
            local command_path
            command_path=$(echo "$line" | awk '{print $2}')
            local command_name
            command_name=$(basename "$command_path" 2>/dev/null)
            
            # Skip empty lines
            [ -z "$pid" ] && continue
            
            # Get architecture using process_info
            local arch
            arch=$(ps -p "$pid" -o arch= 2>/dev/null)
            
            if [ "$arch" = "x86_64" ]; then
                rosetta_count=$((rosetta_count + 1))
                
                # Check if it has an ARM64 alternative
                local native_alternative=""
                local arm_command_path=""
                
                if [[ "$command_path" == "/usr/local/"* ]]; then
                    # Check if an ARM version exists in /opt/homebrew
                    arm_command_path="/opt/homebrew/${command_path#/usr/local/}"
                    if [ -f "$arm_command_path" ]; then
                        native_alternative="$arm_command_path"
                    fi
                fi
                
                # Categorize Rosetta processes
                if [[ "$command_name" == "node" || 
                      "$command_name" == "npm" || 
                      "$command_name" == "java" || 
                      "$command_name" == "python"* || 
                      "$command_name" == "ruby" || 
                      "$command_name" == "perl" || 
                      "$command_name" == "gcc" || 
                      "$command_name" == "clang" ]]; then
                    dev_processes+=("$command_name (PID: $pid)")
                    
                    # Add to report
                    echo "- $command_name (PID: $pid)" >> "$REPORT_FILE"
                    
                    if [ -n "$native_alternative" ]; then
                        echo "  - Native alternative: $native_alternative" >> "$REPORT_FILE"
                    fi
                    
                    log_issue "WARNING" "Development tool '$command_name' (PID: $pid) is running under Rosetta 2" \
                             "Consider using the ARM64 native version if available"
                fi
                
                if [ "$VERBOSE" = true ]; then
                    print_verbose "Process $command_name (PID: $pid) is running under Rosetta 2"
                    if [ -n "$native_alternative" ]; then
                        print_verbose "  Native alternative: $native_alternative"
                    fi
                fi
            fi
        done <<< "$processes"
        
        if [ "$rosetta_count" -eq 0 ]; then
            print_message "$GREEN" "✓ No processes running under Rosetta 2"
            echo "No processes detected running under Rosetta 2." >> "$REPORT_FILE"
        else
            print_message "$YELLOW" "⚠ Found $rosetta_count processes running under Rosetta 2"
            
            if [ ${#dev_processes[@]} -gt 0 ]; then
                print_message "$YELLOW" "⚠ Development tools running under Rosetta 2:"
                for proc in "${dev_processes[@]}"; do
                    echo "  - $proc"
                done
            fi
        fi
    else
        print_message "$BLUE" "Skipping Rosetta process check on Intel Mac"
        echo "Skipping Rosetta process check on Intel Mac." >> "$REPORT_FILE"
    fi
    
    echo >> "$REPORT_FILE"
}

# Check PATH configuration
check_path_configuration() {
    print_header "Checking PATH Configuration"
    
    # Add PATH section to report
    echo "## PATH Environment Variable" >> "$REPORT_FILE"
    
    # Get PATH environment variable
    local path_var="$PATH"
    print_verbose "Current PATH: $path_var"
    
    # Add to report
    echo '```' >> "$REPORT_FILE"
    echo "$path_var" | tr ':' '\n' >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    
    if [ "$IS_APPLE_SILICON" = true ]; then
        # Check if /opt/homebrew/bin is in PATH
        if [[ $path_var != *"/opt/homebrew/bin"* ]] && [ -d "/opt/homebrew/bin" ]; then
            log_issue "WARNING" "Apple Silicon Homebrew directory (/opt/homebrew/bin) is not in PATH" \
                     "Add 'export PATH=/opt/homebrew/bin:\$PATH' to your shell profile"
        fi
        
        # Check if /opt/homebrew/bin comes before /usr/local/bin for Apple Silicon
        if [[ $path_var == *"/usr/local/bin"*"/opt/homebrew/bin"* ]]; then
            log_issue "WARNING" "Intel path (/usr/local/bin) appears before Apple Silicon path (/opt/homebrew/bin) in PATH" \
                     "Reorder PATH in your shell profile to put /opt/homebrew/bin first"
        fi
    else
        # Check if /usr/local/bin is in PATH for Intel
        if [[ $path_var != *"/usr/local/bin"* ]] && [ -d "/usr/local/bin" ]; then
            log_issue "WARNING" "Intel Homebrew directory (/usr/local/bin) is not in PATH" \
                     "Add 'export PATH=/usr/local/bin:\$PATH' to your shell profile"
        fi
    fi
    
    echo >> "$REPORT_FILE"
}

# =========================================================
# DOCKER CHECKS
# =========================================================

check_docker() {
    print_header "Checking Docker Configuration"
    
    # Add Docker section to report
    echo "## Docker Configuration" >> "$REPORT_FILE"
    
    # Check if Docker is installed
    if command -v docker >/dev/null 2>&1; then
        print_message "$GREEN" "✓ Docker is installed"
        echo "- Docker is installed" >> "$REPORT_FILE"
        
        # Check Docker version
        local docker_version
        docker_version=$(docker --version 2>/dev/null)
        print_message "$BLUE" "Docker version: $docker_version"
        echo "- **Version:** $docker_version" >> "$REPORT_FILE"
        
        # Check Docker architecture
        local docker_path
        local docker_arch
        
        docker_path=$(which docker)
        docker_arch=$(check_binary_arch "$docker_path")
        
        print_message "$BLUE" "Docker binary architecture: $docker_arch"
        echo "- **Binary Architecture:** $docker_arch" >> "$REPORT_FILE"
        
        if [ "$IS_APPLE_SILICON" = true ] && [[ "$docker_arch" == *"x86_64"* ]] && [[ "$docker_arch" != *"universal"* ]]; then
            log_issue "WARNING" "Docker is running under Rosetta 2 ($docker_arch)" \
                     "Install the Apple Silicon version of Docker Desktop from https://www.docker.com/products/docker-desktop"
        fi
        
        # Check if Docker is running
        if is_test_mode; then
            echo "[TEST MODE] Would check if Docker is running"
        else
            if docker info >/dev/null 2>&1; then
                print_message "$GREEN" "✓ Docker daemon is running"
                echo "- Docker daemon is running" >> "$REPORT_FILE"
                
                # Check platform
                local docker_platform
                docker_platform=$(docker info --format '{{.Architecture}}' 2>/dev/null)
                
                if [ -n "$docker_platform" ]; then
                    print_message "$BLUE" "Docker platform: $docker_platform"
                    echo "- **Platform:** $docker_platform" >> "$REPORT_FILE"
                    
                    if [ "$IS_APPLE_SILICON" = true ] && [ "$docker_platform" != "arm64" ]; then
                        log_issue "WARNING" "Docker is not running in native ARM64 mode ($docker_platform)" \
                                 "Check Docker Desktop settings to enable ARM64 support"
                    fi
                fi
                
                # Check for running containers
                local containers
                containers=$(docker ps --format '{{.Image}} ({{.ID}})' 2>/dev/null)
                
                if [ -n "$containers" ]; then
                    print_message "$BLUE" "Running containers found:"
                    echo "### Running Containers" >> "$REPORT_FILE"
                    
                    while IFS= read -r container; do
                        echo "  - $container"
                        echo "- $container" >> "$REPORT_FILE"
                        
                        # Get container architecture
                        local container_id
                        container_id=$(echo "$container" | sed -E 's/.*\(([a-zA-Z0-9]+)\)/\1/')
                        
                        if [ -n "$container_id" ]; then
                            local container_arch
                            container_arch=$(docker inspect --format='{{.Architecture}}' "$container_id" 2>/dev/null)
                            
                            if [ -n "$container_arch" ]; then
                                echo "  - Architecture: $container_arch"
                                echo "  - Architecture: $container_arch" >> "$REPORT_FILE"
                                
                                if [ "$IS_APPLE_SILICON" = true ] && [ "$container_arch" = "amd64" ]; then
                                    log_issue "INFO" "Container $container is running with x86_64/amd64 architecture on Apple Silicon" \
                                             "This container is using emulation, which may impact performance"
                                fi
                            fi
                        fi
                    done <<< "$containers"
                else
                    print_message "$BLUE" "No running containers"
                    echo "- No running containers" >> "$REPORT_FILE"
                fi
                
                # Check Docker configuration file
                if [ -f "$HOME/.docker/config.json" ]; then
                    print_verbose "Docker config file found: $HOME/.docker/config.json"
                    
                    # Check for platform configurations
                    if grep -q "\"platform\"" "$HOME/.docker/config.json" 2>/dev/null; then
                        local platform_config
                        platform_config=$(grep -A 3 "\"platform\"" "$HOME/.docker/config.json" 2>/dev/null)
                        
                        print_verbose "Platform configuration found: $platform_config"
                        echo "### Docker Platform Configuration" >> "$REPORT_FILE"
                        echo '```json' >> "$REPORT_FILE"
                        echo "$platform_config" >> "$REPORT_FILE"
                        echo '```' >> "$REPORT_FILE"
                        
                        if [ "$IS_APPLE_SILICON" = true ] && [[ "$platform_config" == *"linux/amd64"* ]]; then
                            log_issue "WARNING" "Docker is configured to use x86_64/amd64 platform by default" \
                                     "Update Docker configuration to use linux/arm64 platform for better performance"
                        fi
                    fi
                fi
            else
                print_message "$YELLOW" "⚠ Docker is installed but not running"
                echo "- Docker is installed but not running" >> "$REPORT_FILE"
                log_issue "INFO" "Docker is installed but not running" \
                         "Start Docker Desktop from the Applications folder"
            fi
        fi
    else
        print_message "$BLUE" "Docker is not installed, skipping Docker checks"
        echo "- Docker is not installed" >> "$REPORT_FILE"
    fi
    
    echo >> "$REPORT_FILE"
}

# =========================================================
# DEVELOPMENT TOOLS CHECKS
# =========================================================

check_development_tools() {
    print_header "Checking Common Development Tools"
    
    # Add development tools section to report
    echo "## Development Tools" >> "$REPORT_FILE"
    
    # List of common development tools to check
    local tools=(
        "git"
        "make"
        "gcc"
        "clang"
        "cmake"
        "java"
        "mvn"
        "gradle"
        "ruby"
        "perl"
        "php"
        "go"
        "rust"
        "cargo"
        "swift"
        "xcodebuild"
    )
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local tool_path
            local tool_arch
            local tool_version
            
            tool_path=$(which "$tool")
            tool_arch=$(check_binary_arch "$tool_path")
            
            # Try to get version
            tool_version=$("$tool" --version 2>/dev/null || "$tool" -version 2>/dev/null || echo "Unknown version")
            
            print_message "$GREEN" "✓ $tool is installed: $tool_arch"
            if [ "$VERBOSE" = true ]; then
                print_verbose "$tool version: $tool_version"
            fi
            
            echo "### $tool" >> "$REPORT_FILE"
            echo "- **Path:** $tool_path" >> "$REPORT_FILE"
            echo "- **Architecture:** $tool_arch" >> "$REPORT_FILE"
            echo "- **Version:** $tool_version" >> "$REPORT_FILE"
            
            if [ "$IS_APPLE_SILICON" = true ] && [[ "$tool_arch" == *"x86_64"* ]] && [[ "$tool_arch" != *"universal"* ]]; then
                log_issue "WARNING" "$tool is running under Rosetta 2 ($tool_arch)" \
                         "Consider installing the ARM64 native version if available"
            fi
            
            echo >> "$REPORT_FILE"
        fi
    done
    
    # Check XCode Command Line Tools specifically
    if xcode-select -p &>/dev/null; then
        local xcode_path
        xcode_path=$(xcode-select -p)
        
        print_message "$GREEN" "✓ XCode Command Line Tools installed at: $xcode_path"
        echo "### XCode Command Line Tools" >> "$REPORT_FILE"
        echo "- **Path:** $xcode_path" >> "$REPORT_FILE"
        
        # Check for architecture-specific issues with XCode
        if [ "$IS_APPLE_SILICON" = true ]; then
            # Check if running the latest XCode version supporting Apple Silicon
            local xcodebuild_version
            xcodebuild_version=$(xcodebuild -version 2>/dev/null | head -n 1)
            
            echo "- **Version:** $xcodebuild_version" >> "$REPORT_FILE"
            
            if [ -n "$xcodebuild_version" ]; then
                local xcode_major_version
                xcode_major_version=$(echo "$xcodebuild_version" | sed -E 's/Xcode ([0-9]+)\..*/\1/')
                
                if [ -n "$xcode_major_version" ] && [ "$xcode_major_version" -lt 12 ]; then
                    log_issue "CRITICAL" "XCode version $xcodebuild_version does not fully support Apple Silicon" \
                             "Update to XCode 12 or newer for proper Apple Silicon support"
                fi
            fi
        fi
        
        echo >> "$REPORT_FILE"
    else
        print_message "$YELLOW" "⚠ XCode Command Line Tools not found"
        log_issue "WARNING" "XCode Command Line Tools not found" \
                 "Install XCode Command Line Tools with: xcode-select --install"
        echo "### XCode Command Line Tools: Not installed" >> "$REPORT_FILE"
        echo >> "$REPORT_FILE"
    fi
}

# =========================================================
# REPORT GENERATION
# =========================================================

generate_report() {
    print_header "Generating Report"
    
    # Add report header (initial sections are added by individual check functions)
    echo "# Silicon Compatibility Scanner Report" > "$REPORT_FILE"
    echo "Generated on: $(date)" >> "$REPORT_FILE"
    echo "System: $(uname -s) $(uname -r) $(uname -m)" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
    
    echo "## Summary" >> "$REPORT_FILE"
    echo "- **Critical issues:** $CRITICAL_COUNT" >> "$REPORT_FILE"
    echo "- **Warnings:** $WARNING_COUNT" >> "$REPORT_FILE"
    echo "- **Information:** $INFO_COUNT" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
    
    # Add final recommendations section
    echo "## Recommendations" >> "$REPORT_FILE"
    
    if [ $CRITICAL_COUNT -gt 0 ]; then
        echo "### High Priority" >> "$REPORT_FILE"
        echo "Address all critical issues listed above to ensure compatibility with Apple Silicon." >> "$REPORT_FILE"
    fi
    
    echo "### General Recommendations" >> "$REPORT_FILE"
    echo "1. **Favor native ARM64 applications** over Rosetta 2 emulation when possible" >> "$REPORT_FILE"
    echo "2. **Use universal binaries** when available for maximum compatibility" >> "$REPORT_FILE"
    echo "3. **Check Docker images** for multi-architecture support (arm64/amd64)" >> "$REPORT_FILE"
    echo "4. **Update development tools** to their latest versions for better Apple Silicon support" >> "$REPORT_FILE"
    echo "5. **Configure PATH environment** to prioritize Apple Silicon paths on M-series Macs" >> "$REPORT_FILE"
    
    # Add resources section
    echo "## Additional Resources" >> "$REPORT_FILE"
    echo "- [Apple Silicon Guide for Developers](https://developer.apple.com/documentation/apple-silicon)" >> "$REPORT_FILE"
    echo "- [Homebrew on Apple Silicon](https://docs.brew.sh/Installation#macos-requirements)" >> "$REPORT_FILE"
    echo "- [Docker Desktop for Apple Silicon](https://docs.docker.com/desktop/mac/apple-silicon/)" >> "$REPORT_FILE"
    echo "- [Rosetta 2 Translation Environment](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment)" >> "$REPORT_FILE"
    
    print_message "$GREEN" "Report generated: $REPORT_FILE"
}

# =========================================================
# MAIN EXECUTION
# =========================================================

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --test)
                TEST_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo
                echo "Options:"
                echo "  --test      Run in test mode (no changes will be made)"
                echo "  --verbose   Show more detailed output"
                echo "  --help      Show this help message"
                exit 0
                ;;
        esac
    done
}

# Display welcome message
show_welcome() {
    echo -e "${BOLD}Silicon Compatibility Scanner v${VERSION}${RESET}"
    echo "This tool scans your system for Apple Silicon compatibility issues"
    echo "and provides actionable recommendations."
    echo
    
    if is_test_mode; then
        echo -e "${YELLOW}Running in TEST MODE - no changes will be made${RESET}"
        echo
    fi
}

# Main function
main() {
    parse_args "$@"
    show_welcome
    
    # Initialize report file , defined already in the script - as name -
    > "$REPORT_FILE"
    
    # Run checks
    detect_architecture
    check_package_managers
    check_path_configuration
    check_rosetta_processes
    check_docker
    check_development_tools
    
    # Generate final report
    generate_report
    
    # Display summary
    print_header "Scan Complete"
    echo -e "Found ${RED}${CRITICAL_COUNT} critical issues${RESET}, ${YELLOW}${WARNING_COUNT} warnings${RESET}, and ${GREEN}${INFO_COUNT} informational items${RESET}"
    echo "See the full report at: $REPORT_FILE"
    
    # Provide next steps
    echo
    echo -e "${BOLD}Next Steps:${RESET}"
    echo "1. Review the detailed report"
    echo "2. Address critical issues first"
    echo "3. Follow the specific solution recommendations for each issue"
    
    if [ $CRITICAL_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
        echo
        echo -e "${GREEN}Congratulations! Your system appears to be well-configured for Apple Silicon.${RESET}"
    fi
}

# Run the main function with all script arguments
main "$@"
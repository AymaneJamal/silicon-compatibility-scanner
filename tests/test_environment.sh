#!/bin/bash
#
# Test Environment for Silicon Compatibility Scanner
# This script creates a comprehensive test environment to safely validate the scanner
#

# Text colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

# Test directory
TEST_DIR="./test_environment"

# Clean up previous test environment if it exists
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        echo "Cleaning up previous test environment..."
        rm -rf "$TEST_DIR"
    fi
}

# Create test environment directory structure
create_directory_structure() {
    echo "Creating test environment directory structure..."
    
    # System directories
    mkdir -p "$TEST_DIR/usr/local/bin"
    mkdir -p "$TEST_DIR/usr/local/opt/node/bin"
    mkdir -p "$TEST_DIR/usr/local/opt/python/bin"
    mkdir -p "$TEST_DIR/opt/homebrew/bin"
    mkdir -p "$TEST_DIR/opt/homebrew/opt/node/bin"
    mkdir -p "$TEST_DIR/opt/homebrew/opt/python/bin"
    
    # Application directories
    mkdir -p "$TEST_DIR/Applications/Docker.app/Contents/MacOS"
    mkdir -p "$TEST_DIR/Applications/Visual Studio Code.app/Contents/MacOS"
    
    # User directories
    mkdir -p "$TEST_DIR/Projects/node-project/node_modules/native-module"
    mkdir -p "$TEST_DIR/Projects/python-project/venv"
    
    # Docker directories
    mkdir -p "$TEST_DIR/docker/config"
    mkdir -p "$TEST_DIR/Library/Containers/com.docker.docker"
    
    # XCode directories
    mkdir -p "$TEST_DIR/Library/Developer/CommandLineTools"
    mkdir -p "$TEST_DIR/Applications/Xcode.app/Contents/Developer"
    
    # Home directory structure
    mkdir -p "$TEST_DIR/home/.docker"
    mkdir -p "$TEST_DIR/home/.npm"
    mkdir -p "$TEST_DIR/home/.node-gyp"
    mkdir -p "$TEST_DIR/home/.python"
    mkdir -p "$TEST_DIR/home/.config"
}

# Create mock executable files
create_mock_executables() {
    echo "Creating mock executable files..."
    
    # Create mock Homebrew binaries
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/brew"
    echo 'if [ "$1" = "--prefix" ]; then echo "/usr/local"; else echo "Homebrew 3.6.0 (Intel)"; fi' >> "$TEST_DIR/usr/local/bin/brew"
    chmod +x "$TEST_DIR/usr/local/bin/brew"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/brew"
    echo 'if [ "$1" = "--prefix" ]; then echo "/opt/homebrew"; else echo "Homebrew 3.6.0 (ARM)"; fi' >> "$TEST_DIR/opt/homebrew/bin/brew"
    chmod +x "$TEST_DIR/opt/homebrew/bin/brew"
    
    # Create mock Node.js binaries
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/node"
    echo 'echo "v16.14.0 (Intel)"' >> "$TEST_DIR/usr/local/bin/node"
    chmod +x "$TEST_DIR/usr/local/bin/node"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/node"
    echo 'echo "v16.14.0 (ARM)"' >> "$TEST_DIR/opt/homebrew/bin/node"
    chmod +x "$TEST_DIR/opt/homebrew/bin/node"
    
    # Create mock npm binaries
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/npm"
    echo 'echo "8.3.1 (Intel)"' >> "$TEST_DIR/usr/local/bin/npm"
    chmod +x "$TEST_DIR/usr/local/bin/npm"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/npm"
    echo 'echo "8.3.1 (ARM)"' >> "$TEST_DIR/opt/homebrew/bin/npm"
    chmod +x "$TEST_DIR/opt/homebrew/bin/npm"
    
    # Create mock Python binaries
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/python3"
    echo 'echo "Python 3.9.10 (Intel)"' >> "$TEST_DIR/usr/local/bin/python3"
    chmod +x "$TEST_DIR/usr/local/bin/python3"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/python3"
    echo 'echo "Python 3.9.10 (ARM)"' >> "$TEST_DIR/opt/homebrew/bin/python3"
    chmod +x "$TEST_DIR/opt/homebrew/bin/python3"
    
    # Create mock pip binaries
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/pip3"
    echo 'echo "pip 22.0.3 (Intel)"' >> "$TEST_DIR/usr/local/bin/pip3"
    chmod +x "$TEST_DIR/usr/local/bin/pip3"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/pip3"
    echo 'echo "pip 22.0.3 (ARM)"' >> "$TEST_DIR/opt/homebrew/bin/pip3"
    chmod +x "$TEST_DIR/opt/homebrew/bin/pip3"
    
    # Create mock Docker binary
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/docker"
    echo 'if [ "$1" = "--version" ]; then echo "Docker version 20.10.12, build e91ed57 (Intel)"; elif [ "$1" = "info" ]; then echo "{\"Architecture\": \"x86_64\"}"; else echo "Docker (Intel)"; fi' >> "$TEST_DIR/usr/local/bin/docker"
    chmod +x "$TEST_DIR/usr/local/bin/docker"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/docker"
    echo 'if [ "$1" = "--version" ]; then echo "Docker version 20.10.12, build e91ed57 (ARM)"; elif [ "$1" = "info" ]; then echo "{\"Architecture\": \"arm64\"}"; else echo "Docker (ARM)"; fi' >> "$TEST_DIR/opt/homebrew/bin/docker"
    chmod +x "$TEST_DIR/opt/homebrew/bin/docker"
    
    # Create mock git binary
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/git"
    echo 'if [ "$1" = "--version" ]; then echo "git version 2.35.1 (Intel)"; else echo "Git (Intel)"; fi' >> "$TEST_DIR/usr/local/bin/git"
    chmod +x "$TEST_DIR/usr/local/bin/git"
    
    echo '#!/bin/bash' > "$TEST_DIR/opt/homebrew/bin/git"
    echo 'if [ "$1" = "--version" ]; then echo "git version 2.35.1 (ARM)"; else echo "Git (ARM)"; fi' >> "$TEST_DIR/opt/homebrew/bin/git"
    chmod +x "$TEST_DIR/opt/homebrew/bin/git"
    
    # Create mock XCode binary
    echo '#!/bin/bash' > "$TEST_DIR/usr/bin/xcodebuild"
    echo 'echo "Xcode 13.2.1"' >> "$TEST_DIR/usr/bin/xcodebuild"
    chmod +x "$TEST_DIR/usr/bin/xcodebuild"
    
    # Create mock xcode-select binary
    echo '#!/bin/bash' > "$TEST_DIR/usr/bin/xcode-select"
    echo 'if [ "$1" = "-p" ]; then echo "/Applications/Xcode.app/Contents/Developer"; else echo "xcode-select: error: command not found"; fi' >> "$TEST_DIR/usr/bin/xcode-select"
    chmod +x "$TEST_DIR/usr/bin/xcode-select"
    
    # Create mock swift binary
    echo '#!/bin/bash' > "$TEST_DIR/usr/bin/swift"
    echo 'if [ "$1" = "--version" ]; then echo "swift-driver version: 1.26.21 Apple Swift version 5.5.2"; else echo "Swift"; fi' >> "$TEST_DIR/usr/bin/swift"
    chmod +x "$TEST_DIR/usr/bin/swift"
    
    # Create mock Java binary
    echo '#!/bin/bash' > "$TEST_DIR/usr/bin/java"
    echo 'if [ "$1" = "-version" ]; then echo "openjdk version \"11.0.14\" 2022-01-18"; else echo "Java"; fi' >> "$TEST_DIR/usr/bin/java"
    chmod +x "$TEST_DIR/usr/bin/java"
}

# Create mock configuration files
create_mock_configs() {
    echo "Creating mock configuration files..."
    
    # Create mock Docker config.json
    cat > "$TEST_DIR/home/.docker/config.json" << EOF
{
  "auths": {},
  "credsStore": "osxkeychain",
  "currentContext": "desktop-linux",
  "plugins": {
    "buildx": {
      "enabled": true
    }
  },
  "experimental": "enabled",
  "platform": "linux/amd64"
}
EOF
    
    # Create mock package.json with native dependencies
    cat > "$TEST_DIR/Projects/node-project/package.json" << EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.17.3",
    "sqlite3": "^5.0.2",
    "node-gyp": "^8.4.1",
    "sharp": "^0.30.1"
  },
  "devDependencies": {
    "electron": "^17.0.1"
  }
}
EOF
    
    # Create mock binding.gyp for native module
    cat > "$TEST_DIR/Projects/node-project/node_modules/native-module/binding.gyp" << EOF
{
  "targets": [
    {
      "target_name": "native_module",
      "sources": [ "src/native_module.cc" ]
    }
  ]
}
EOF
    
    # Create mock requirements.txt with native dependencies
    cat > "$TEST_DIR/Projects/python-project/requirements.txt" << EOF
numpy==1.22.2
pandas==1.4.1
matplotlib==3.5.1
tensorflow==2.8.0
scikit-learn==1.0.2
Pillow==9.0.1
EOF
}

# Generate mock process list for testing
generate_mock_processes() {
    echo "Generating mock process list..."
    
    cat > "$TEST_DIR/processes.txt" << EOF
PID   TTY     TIME CMD                                                      ARCH
1     ??      0:00 /sbin/launchd                                            arm64
321   ??      0:05 /usr/sbin/SystemUIServer                                 arm64
456   ??      1:23 /Applications/Utilities/Terminal.app/Contents/MacOS/Terminal arm64
789   ttys000 0:00 /bin/bash                                                arm64
1234  ttys000 0:01 /usr/local/bin/node                                      x86_64
1235  ttys000 0:02 /opt/homebrew/bin/python3                                arm64
1236  ttys000 0:03 /usr/bin/java                                            arm64
1237  ttys000 0:04 /usr/local/bin/docker                                    x86_64
1238  ttys000 0:05 /usr/local/bin/npm                                       x86_64
1239  ttys000 0:01 /opt/homebrew/bin/git                                    arm64
1240  ttys000 0:02 /usr/local/bin/vim                                       x86_64
1241  ttys000 0:03 /usr/bin/python3                                         arm64
EOF
}

# Generate mock Homebrew list output
generate_mock_homebrew_list() {
    echo "Generating mock Homebrew package list..."
    
    cat > "$TEST_DIR/homebrew_list.txt" << EOF
node
python@3.9
git
vim
docker
wget
curl
openssl
sqlite
postgresql
mongodb
redis
EOF
}

# Create file command output simulator
create_file_command_simulator() {
    echo "Creating file command simulator..."
    
    cat > "$TEST_DIR/mock_file_command.sh" << EOF
#!/bin/bash

# Mock file command that returns different architecture info based on the binary path
binary_path="\$1"

if [[ "\$binary_path" == *"/opt/homebrew/"* ]]; then
    echo "\$binary_path: Mach-O 64-bit executable arm64"
elif [[ "\$binary_path" == *"/usr/local/"* ]]; then
    echo "\$binary_path: Mach-O 64-bit executable x86_64"
elif [[ "\$binary_path" == *"/usr/bin/"* ]]; then
    echo "\$binary_path: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64e:Mach-O 64-bit executable arm64e]"
elif [[ "\$binary_path" == *"/Applications/"* ]]; then
    echo "\$binary_path: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64e:Mach-O 64-bit executable arm64e]"
else
    echo "\$binary_path: Mach-O 64-bit executable arm64"
fi
EOF
    chmod +x "$TEST_DIR/mock_file_command.sh"
}

# Create architecture simulation script
create_arch_simulation_script() {
    echo "Creating architecture simulation script..."
    
    cat > "$TEST_DIR/simulate_arch.sh" << EOF
#!/bin/bash

# Script to simulate different architectures for testing the Silicon Compatibility Scanner
# Usage: ./simulate_arch.sh [arm64|x86_64]

# Default to arm64 if no architecture specified
ARCH="\${1:-arm64}"

if [ "\$ARCH" = "arm64" ]; then
    export SIMULATED_ARCH="arm64"
    export SIMULATED_HW_OPTIONAL_ARM64="1"
    export SIMULATED_CHIP_MODEL="Apple M1 Pro"
    export SIMULATED_MACOS_VERSION="12.2.1"
    echo "Simulating Apple Silicon (ARM64) environment"
elif [ "\$ARCH" = "x86_64" ]; then
    export SIMULATED_ARCH="x86_64"
    export SIMULATED_HW_OPTIONAL_ARM64="0"
    export SIMULATED_CHIP_MODEL="Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz"
    export SIMULATED_MACOS_VERSION="12.2.1"
    echo "Simulating Intel (x86_64) environment"
else
    echo "Usage: \$0 [arm64|x86_64]"
    exit 1
fi

# Create a mock PATH environment that depends on architecture
if [ "\$ARCH" = "arm64" ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
else
    export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
fi

# Override system commands for testing
function uname() {
    if [ "\$1" = "-m" ]; then
        echo "\$SIMULATED_ARCH"
    elif [ "\$1" = "-s" ]; then
        echo "Darwin"
    elif [ "\$1" = "-r" ]; then
        echo "21.3.0"
    else
        echo "Darwin MacBook-Pro.local 21.3.0 Darwin Kernel Version 21.3.0"
    fi
}
export -f uname

function sysctl() {
    if [ "\$*" = "-n hw.optional.arm64" ]; then
        echo "\$SIMULATED_HW_OPTIONAL_ARM64"
    elif [ "\$*" = "-n machdep.cpu.brand_string" ]; then
        echo "\$SIMULATED_CHIP_MODEL"
    else
        echo "Generic sysctl output"
    fi
}
export -f sysctl

function sw_vers() {
    if [ "\$1" = "-productVersion" ]; then
        echo "\$SIMULATED_MACOS_VERSION"
    elif [ "\$1" = "-productName" ]; then
        echo "macOS"
    elif [ "\$1" = "-buildVersion" ]; then
        echo "21D62"
    else
        echo "ProductName:    macOS"
        echo "ProductVersion: \$SIMULATED_MACOS_VERSION"
        echo "BuildVersion:   21D62"
    fi
}
export -f sw_vers

function file() {
    bash "\$TEST_DIR/mock_file_command.sh" "\$@"
}
export -f file

function ps() {
    # If checking for architecture of a process, return simulated values
    if [[ "\$*" == *"-o arch"* ]]; then
        pid=\$(echo "\$*" | grep -o -E '\-p [0-9]+' | cut -d' ' -f2)
        
        # Return architecture based on PID from our mock process list
        if grep -q "^\$pid " "\$TEST_DIR/processes.txt"; then
            arch=\$(grep "^\$pid " "\$TEST_DIR/processes.txt" | awk '{print \$NF}')
            echo "\$arch"
        else
            echo "\$SIMULATED_ARCH"
        fi
    else
        # Return full process list
        cat "\$TEST_DIR/processes.txt"
    fi
}
export -f ps

function brew() {
    if [ "\$1" = "--prefix" ]; then
        if [ "\$SIMULATED_ARCH" = "arm64" ]; then
            echo "/opt/homebrew"
        else
            echo "/usr/local"
        fi
    elif [ "\$1" = "list" ]; then
        cat "\$TEST_DIR/homebrew_list.txt"
    else
        if [ "\$SIMULATED_ARCH" = "arm64" ]; then
            echo "Homebrew 3.6.0 (ARM)"
        else
            echo "Homebrew 3.6.0 (Intel)"
        fi
    fi
}
export -f brew

function which() {
    # Return path based on architecture
    local cmd="\$1"
    
    if [ "\$SIMULATED_ARCH" = "arm64" ]; then
        # Check if this command exists in our simulated ARM path
        if [ -f "\$TEST_DIR/opt/homebrew/bin/\$cmd" ]; then
            echo "/opt/homebrew/bin/\$cmd"
        elif [ -f "\$TEST_DIR/usr/bin/\$cmd" ]; then
            echo "/usr/bin/\$cmd"
        else
            echo "/opt/homebrew/bin/\$cmd"  # Default fallback
        fi
    else
        # Check if this command exists in our simulated Intel path
        if [ -f "\$TEST_DIR/usr/local/bin/\$cmd" ]; then
            echo "/usr/local/bin/\$cmd"
        elif [ -f "\$TEST_DIR/usr/bin/\$cmd" ]; then
            echo "/usr/bin/\$cmd"
        else
            echo "/usr/local/bin/\$cmd"  # Default fallback
        fi
    fi
}
export -f which

function docker() {
    if [ "\$1" = "--version" ]; then
        echo "Docker version 20.10.12, build e91ed57"
    elif [ "\$1" = "info" ]; then
        if [ "\$2" = "--format" ]; then
            if [ "\$SIMULATED_ARCH" = "arm64" ]; then
                echo "arm64"
            else
                echo "x86_64"
            fi
        else
            echo "{\"Architecture\": \"\$SIMULATED_ARCH\"}"
        fi
    elif [ "\$1" = "ps" ]; then
        if [ "\$SIMULATED_ARCH" = "arm64" ]; then
            echo "nginx (1a2b3c4d)"
            echo "mongo (5e6f7g8h)"
            echo "redis (9i10j11k)"
        else
            echo "nginx (1a2b3c4d)"
        fi
    fi
}
export -f docker

# Run the actual scanner with our simulated environment
echo "Running scanner in \$ARCH mode with test flag..."
cd ..
./silicon_scanner.sh --test
EOF
    chmod +x "$TEST_DIR/simulate_arch.sh"
}

# Create mixed architecture test script
create_mixed_arch_test() {
    echo "Creating mixed architecture test script..."
    
    cat > "$TEST_DIR/test_mixed_arch.sh" << EOF
#!/bin/bash

# This script simulates a mixed architecture environment with some ARM and some Intel components
# It's useful for testing the scanner's ability to detect mixed environment issues

export SIMULATED_ARCH="arm64"
export SIMULATED_HW_OPTIONAL_ARM64="1"
export SIMULATED_CHIP_MODEL="Apple M1 Pro"
export SIMULATED_MACOS_VERSION="12.2.1"
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"  # Incorrect PATH order

echo "Simulating mixed architecture environment (ARM64 Mac with Intel paths first in PATH)"

# Override key binaries to simulate mixed environment
function homebrew_prefix() {
    echo "/usr/local"  # Incorrect Homebrew location for ARM64
}
export -f homebrew_prefix

# Run the scanner with our simulated problematic environment
cd ..
./silicon_scanner.sh --test
EOF
    chmod +x "$TEST_DIR/test_mixed_arch.sh"
}

# Create no-Rosetta test
create_no_rosetta_test() {
    echo "Creating no-Rosetta test script..."
    
    cat > "$TEST_DIR/test_no_rosetta.sh" << EOF
#!/bin/bash

# This script simulates an Apple Silicon Mac without Rosetta 2 installed

export SIMULATED_ARCH="arm64"
export SIMULATED_HW_OPTIONAL_ARM64="1"
export SIMULATED_CHIP_MODEL="Apple M1 Pro"
export SIMULATED_MACOS_VERSION="12.2.1"
export ROSETTA_MISSING="true"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

echo "Simulating Apple Silicon environment without Rosetta 2 installed"

# Override check for Rosetta file
function check_file_exists() {
    if [[ "\$1" == *"libRosettaRuntime"* ]]; then
        return 1  # File does not exist
    else
        return 0  # Other files exist
    fi
}
export -f check_file_exists

# Customize the file check
function test -f() {
    if [[ "\$1" == *"libRosettaRuntime"* ]]; then
        return 1  # File does not exist
    else
        return 0  # Other files exist
    fi
}
export -f test

# Run the scanner with our simulated environment
cd ..
./silicon_scanner.sh --test
EOF
    chmod +x "$TEST_DIR/test_no_rosetta.sh"
}

# Main function
main() {
    cleanup
    create_directory_structure
    create_mock_executables
    create_mock_configs
    generate_mock_processes
    generate_mock_homebrew_list
    create_file_command_simulator
    create_arch_simulation_script
    create_mixed_arch_test
    create_no_rosetta_test
    
    echo -e "${GREEN}Test environment created successfully!${RESET}"
    echo
    echo "Available test scripts:"
    echo -e "  ${BLUE}cd $TEST_DIR && ./simulate_arch.sh arm64${RESET}   - Test with Apple Silicon environment"
    echo -e "  ${BLUE}cd $TEST_DIR && ./simulate_arch.sh x86_64${RESET}  - Test with Intel environment"
    echo -e "  ${BLUE}cd $TEST_DIR && ./test_mixed_arch.sh${RESET}       - Test with mixed architecture issues"
    echo -e "  ${BLUE}cd $TEST_DIR && ./test_no_rosetta.sh${RESET}       - Test without Rosetta installed"
    echo
    echo "These tests will run the scanner with the --test flag to prevent any system changes."
}

# Run the main function
main
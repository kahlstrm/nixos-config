#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base URL for AMD FSR DLLs
BASE_URL="https://download.amd.com/dir/bin/amdxcffx64.dll"
REFERER="https://support.amd.com"

# Temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "${BLUE}FSR 4 DLL Version Scanner${NC}"
echo -e "${BLUE}=========================${NC}"

# Global debug flag
DEBUG_MODE=false

# Debug print function
print_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "DEBUG: $*" >&2
    fi
}

# Function to extract version strings from DLL
extract_version_from_dll() {
    local dll_path="$1"
    local version_id="$2"
    
    # Extract strings from DLL and look for semver patterns
    # This looks for patterns like x.y.z or x.y.z.w
    local versions=$(strings "$dll_path" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -V | uniq)
    
    if [[ -n "$versions" ]]; then
        echo -e "${GREEN}Found versions in $version_id:${NC}"
        while IFS= read -r version; do
            echo -e "  ${YELLOW}$version${NC}"
        done <<< "$versions"
        return 0
    else
        echo -e "${RED}No semver versions found in $version_id${NC}"
        return 1
    fi
}

# Function to get directory listing from AMD server
get_directory_listing() {
    echo -e "${BLUE}Fetching directory listing from AMD server...${NC}" >&2
    
    # Try to get the directory listing - parse HTML directory index
    local listing=$(curl -s --referer "$REFERER" "$BASE_URL/" | \
                   grep -oE 'HREF="[^"]*/"' | \
                   sed 's/HREF="//g' | \
                   sed 's/"//g' | \
                   grep -v '^\.\./\?$' | \
                   grep -E '^[0-9a-fA-F]+/' | \
                   sort)
    
    if [[ -z "$listing" ]]; then
        echo -e "${RED}Failed to fetch directory listing or no directories found${NC}" >&2
        return 1
    fi
    
    echo -e "${GREEN}Found directories:${NC}" >&2
    while IFS= read -r dir; do
        [[ -n "$dir" ]] && echo -e "  ${YELLOW}${dir}${NC}" >&2
    done <<< "$listing"
    echo "" >&2
    
    # Only output the listing to stdout
    echo "$listing"
}

# Main execution
main() {
    local quick_mode=false
    local test_version=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick|-q)
                quick_mode=true
                shift
                ;;
            --debug|-d)
                DEBUG_MODE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--quick|-q] [--debug|-d] [--help|-h] [version]"
                echo ""
                echo "Options:"
                echo "  --quick, -q    Only list available directories without downloading DLLs"
                echo "  --debug, -d    Enable debug output"
                echo "  --help, -h     Show this help message"
                echo ""
                echo "Arguments:"
                echo "  version        Test specific FSR version (e.g., 67D435F7d97000)"
                exit 0
                ;;
            --*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                # Positional argument - treat as version
                test_version="$1"
                shift
                ;;
        esac
    done
    
    echo -e "${BLUE}Starting FSR DLL version scan...${NC}"
    echo ""
    
    local found_versions=0

    # Handle specific version or get directory listing
    if [[ -n "$test_version" ]]; then
        echo -e "${BLUE}Testing specific version: ${test_version}${NC}"
        dir_array=("${test_version}/")
    else
        # Get directory listing
        local directories
        if ! directories=$(get_directory_listing); then
            echo -e "${RED}Failed to get directory listing${NC}"
            exit 1
        fi

        # Convert directories to array
        readarray -t dir_array <<< "$directories"
    fi
    
    # Process each directory using for loop
    print_debug "Starting loop with ${#dir_array[@]} directories"
    for dir in "${dir_array[@]}"; do
        print_debug "Loop iteration with dir='$dir'"
        # Skip empty lines
        [[ -z "$dir" ]] && continue
        
        # Remove trailing slash if present
        local clean_dir="${dir%/}"
        
        echo -e "${BLUE}Processing directory: ${clean_dir}${NC}"
        print_debug "About to download DLL for $clean_dir"
        
        # Construct full URL
        local dll_url="${BASE_URL}/${clean_dir}/amdxcffx64.dll"
        local dll_file="${TEMP_DIR}/${clean_dir}_amdxcffx64.dll"
        
        # Download the DLL
        if curl -s --referer "$REFERER" -o "$dll_file" "$dll_url"; then
            # Check if file was actually downloaded (not 404 page)
            if file "$dll_file" | grep -q "PE32+ executable"; then
                echo -e "${GREEN}✓ Downloaded DLL for ${clean_dir}${NC}"
                
                # Extract version information
                print_debug "About to extract versions from $dll_file"
                if extract_version_from_dll "$dll_file" "$clean_dir"; then
                    print_debug "Version extraction succeeded"
                    found_versions=$((found_versions + 1))
                    print_debug "found_versions now = $found_versions"
                else
                    print_debug "Version extraction failed"
                fi
                
                # Calculate SHA256 hash in Nix format
                local dll_sha256=$(sha256sum "$dll_file" | cut -d' ' -f1)
                local nix_hash=$(nix hash to-sri --type sha256 "$dll_sha256" 2>/dev/null || echo "sha256-$(echo -n "$dll_sha256" | xxd -r -p | base64)")
                echo -e "${BLUE}SHA256: ${YELLOW}${nix_hash}${NC}"
                
                print_debug "After version extraction"
            else
                echo -e "${RED}✗ Invalid DLL file for ${clean_dir} (might be 404)${NC}"
                rm -f "$dll_file"
            fi
        else
            echo -e "${RED}✗ Failed to download DLL for ${clean_dir}${NC}"
        fi
        
        echo ""
        print_debug "Completed processing $clean_dir"
    done
    print_debug "Loop completed"
    
    echo -e "${BLUE}Scan completed!${NC}"
    echo -e "${GREEN}Found version information in $found_versions directories${NC}"
    
    # Show current version from default.nix
    echo ""
    echo -e "${BLUE}Current version in default.nix:${NC}"
    if [[ -f "default.nix" ]]; then
        local current_version=$(grep -o 'fsrVersion = "[^"]*"' default.nix | cut -d'"' -f2)
        echo -e "${YELLOW}$current_version${NC}"
    else
        echo -e "${RED}default.nix not found in current directory${NC}"
    fi
}

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

if ! command -v strings &> /dev/null; then
    echo -e "${RED}Error: strings (binutils) is required but not installed${NC}"
    exit 1
fi

if ! command -v file &> /dev/null; then
    echo -e "${RED}Error: file is required but not installed${NC}"
    exit 1
fi

# Run main function
main "$@"

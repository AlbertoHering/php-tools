#!/bin/sh

# Define the Docker image name
IMAGE_NAME="php-tools-7.4"
DOCKERFILE_PATH="./Dockerfile"

# Define the source directory (default is ./src, modify if needed)
SRC_DIR="./src"
BACKUP_DIR="./backup"

# Default PHPStan level
DEFAULT_LEVEL=0

# Function to build the Docker image if it doesn't exist
build_image_if_not_exists() {
    if ! docker images | grep -q "$IMAGE_NAME"; then
        echo "Docker image '$IMAGE_NAME' not found. Building the image..."
        if [ -f "$DOCKERFILE_PATH" ]; then
            docker build -t $IMAGE_NAME .
            if [ $? -ne 0 ]; then
                echo "Error: Failed to build the Docker image."
                exit 1
            fi
        else
            echo "Error: Dockerfile not found at $DOCKERFILE_PATH."
            exit 1
        fi
    else
        echo "Docker image '$IMAGE_NAME' found. Proceeding..."
    fi
}

# Function to backup original files
backup_original_files() {
    echo "Backing up original files to $BACKUP_DIR..."
    mkdir -p $BACKUP_DIR
    cp -r $SRC_DIR/* $BACKUP_DIR/
}

# Function to run PHPStan with an optional level argument
run_phpstan() {
    PHPSTAN_LEVEL=${1:-$DEFAULT_LEVEL}
    echo "Running PHPStan with level $PHPSTAN_LEVEL..."
    docker run --rm -v $(pwd):/app $IMAGE_NAME phpstan analyse --level=$PHPSTAN_LEVEL /app/${SRC_DIR}
}

# Function to run PHP_CodeSniffer
run_phpcs() {
    echo "Running PHP_CodeSniffer to check for coding standards issues..."
    docker run --rm -v $(pwd):/app $IMAGE_NAME phpcs /app/${SRC_DIR}
}

# Function to run PHP Code Beautifier to fix code standard issues
run_phpcbf() {
    echo "Running PHP Code Beautifier (PHP_CBF) to fix coding standard issues..."
    docker run --rm -v $(pwd):/app $IMAGE_NAME phpcbf /app/${SRC_DIR}
}

# Function to run PHP-CS-Fixer to fix code style
run_php_cs_fixer() {
    echo "Running PHP-CS-Fixer to fix code style issues..."
    docker run --rm -v $(pwd):/app $IMAGE_NAME php-cs-fixer fix /app/${SRC_DIR}
}

# Function to show usage
show_help() {
    echo "Usage: $0 [phpstan|phpcs|phpcbf|phpcsfix|all] [--level PHPStan-level]"
    echo "    phpstan  - Run PHPStan to analyse code"
    echo "    phpcs    - Run PHP_CodeSniffer to check coding standards"
    echo "    phpcbf   - Run PHP Code Beautifier to fix coding standards"
    echo "    phpcsfix - Run PHP-CS-Fixer to automatically fix code style issues"
    echo "    all      - Run all tools in sequence (PHP-CS-Fixer, PHP Code Beautifier, PHP_CodeSniffer, PHPStan)"
    echo ""
    echo "Options:"
    echo "    --level  - Specify PHPStan rule level (default: $DEFAULT_LEVEL)"
    echo "    --help   - Display this help message"
}

# Parse optional arguments
PHPSTAN_LEVEL=$DEFAULT_LEVEL
for arg in "$@"; do
    case $arg in
        --level=*)
        PHPSTAN_LEVEL="${arg#*=}"
        shift # Remove --level from the argument list
        ;;
        --help)
        show_help
        exit 0
        ;;
    esac
done

# Check the passed argument
if [ "$#" -eq 0 ]; then
    show_help
    exit 1
fi

# Build the Docker image if it's not available
build_image_if_not_exists

# Execute the chosen tool or all
case "$1" in
    phpstan)
        run_phpstan $PHPSTAN_LEVEL
        ;;
    phpcs)
        run_phpcs
        ;;
    phpcbf)
        run_phpcbf
        ;;
    phpcsfix)
        run_php_cs_fixer
        ;;
    all)
        # Backup original files first
        backup_original_files
        # Run fixers first to fix issues before checking with PHPCS
        run_php_cs_fixer    # Fix code style issues
        run_phpcbf          # Fix PHP_CodeSniffer issues
        run_phpcs           # Now check with PHPCS after auto-fixing
        run_phpstan $PHPSTAN_LEVEL
        ;;
    *)
        show_help
        exit 1
        ;;
esac

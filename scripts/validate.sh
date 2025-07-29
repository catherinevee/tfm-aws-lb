#!/bin/bash

# Terraform AWS Load Balancer Module Validation Script
# This script validates the Terraform module for common issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    if ! command -v tflint &> /dev/null; then
        print_warning "TFLint is not installed. Install it for better validation."
    fi
    
    if ! command -v terraform-docs &> /dev/null; then
        print_warning "terraform-docs is not installed. Install it for documentation generation."
    fi
    
    print_status "Requirements check completed"
}

# Validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    # Initialize Terraform
    terraform init -backend=false
    
    # Validate configuration
    if terraform validate; then
        print_status "Terraform validation passed"
    else
        print_error "Terraform validation failed"
        exit 1
    fi
}

# Format Terraform code
format_terraform() {
    print_status "Formatting Terraform code..."
    
    if terraform fmt -check -recursive; then
        print_status "Terraform formatting is correct"
    else
        print_warning "Terraform code needs formatting. Run 'terraform fmt -recursive' to fix."
    fi
}

# Run TFLint if available
run_tflint() {
    if command -v tflint &> /dev/null; then
        print_status "Running TFLint..."
        
        # Initialize TFLint
        tflint --init
        
        if tflint; then
            print_status "TFLint validation passed"
        else
            print_error "TFLint validation failed"
            exit 1
        fi
    else
        print_warning "Skipping TFLint (not installed)"
    fi
}

# Check for security issues
check_security() {
    print_status "Checking for security issues..."
    
    # Check for hardcoded secrets
    if grep -r "password\|secret\|key" . --exclude-dir=.git --exclude-dir=.terraform | grep -v "example\|test" | grep -v "variable\|output"; then
        print_warning "Potential hardcoded secrets found. Review the code."
    else
        print_status "No obvious hardcoded secrets found"
    fi
    
    # Check for public access
    if grep -r "0.0.0.0/0" . --exclude-dir=.git --exclude-dir=.terraform | grep -v "example\|test"; then
        print_warning "Public access (0.0.0.0/0) found. Review security groups."
    fi
}

# Validate examples
validate_examples() {
    print_status "Validating examples..."
    
    for example in examples/*/; do
        if [ -d "$example" ]; then
            print_status "Validating example: $example"
            
            cd "$example"
            
            # Initialize and validate
            terraform init -backend=false
            if terraform validate; then
                print_status "Example $example validation passed"
            else
                print_error "Example $example validation failed"
                exit 1
            fi
            
            cd - > /dev/null
        fi
    done
}

# Generate documentation
generate_docs() {
    if command -v terraform-docs &> /dev/null; then
        print_status "Generating documentation..."
        terraform-docs markdown table . > README.md
        print_status "Documentation generated"
    else
        print_warning "Skipping documentation generation (terraform-docs not installed)"
    fi
}

# Main execution
main() {
    print_status "Starting Terraform AWS Load Balancer Module validation..."
    
    check_requirements
    validate_terraform
    format_terraform
    run_tflint
    check_security
    validate_examples
    generate_docs
    
    print_status "Validation completed successfully!"
}

# Run main function
main "$@" 
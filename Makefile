.PHONY: help init plan apply destroy validate fmt lint clean test examples

# Default target
help:
	@echo "Available commands:"
	@echo "  init      - Initialize Terraform"
	@echo "  plan      - Plan Terraform changes"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy Terraform resources"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform code"
	@echo "  lint      - Lint Terraform code"
	@echo "  clean     - Clean up temporary files"
	@echo "  test      - Run tests"
	@echo "  examples  - Run examples"

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan:
	terraform plan

# Apply Terraform changes
apply:
	terraform apply -auto-approve

# Destroy Terraform resources
destroy:
	terraform destroy -auto-approve

# Validate Terraform configuration
validate:
	terraform validate

# Format Terraform code
fmt:
	terraform fmt -recursive

# Lint Terraform code (requires tflint)
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init; \
		tflint; \
	else \
		echo "tflint not found. Install it from https://github.com/terraform-linters/tflint"; \
	fi

# Clean up temporary files
clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
	rm -f *.tfplan

# Run tests (requires terratest)
test:
	@if command -v go >/dev/null 2>&1; then \
		cd test && go test -v -timeout 30m; \
	else \
		echo "Go not found. Install it to run tests."; \
	fi

# Run examples
examples:
	@echo "Running basic example..."
	@cd examples/basic && terraform init && terraform plan
	@echo "Running advanced example..."
	@cd examples/advanced && terraform init && terraform plan
	@echo "Running network example..."
	@cd examples/network && terraform init && terraform plan

# Install development tools
install-tools:
	@echo "Installing development tools..."
	@if command -v curl >/dev/null 2>&1; then \
		curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
	else \
		echo "curl not found. Please install tflint manually."; \
	fi

# Check for security issues (requires terrascan)
security-scan:
	@if command -v terrascan >/dev/null 2>&1; then \
		terrascan scan -i terraform; \
	else \
		echo "terrascan not found. Install it from https://github.com/tenable/terrascan"; \
	fi

# Generate documentation
docs:
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table . > README.md; \
	else \
		echo "terraform-docs not found. Install it from https://github.com/terraform-docs/terraform-docs"; \
	fi

# Pre-commit hooks
pre-commit:
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "pre-commit not found. Install it from https://pre-commit.com"; \
	fi

# Run tfsec (requires tfsec)
tfsec:
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "tfsec not found. Install it from https://github.com/aquasecurity/tfsec"; \
	fi

# Run checkov (requires checkov)
checkov:
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d .; \
	else \
		echo "checkov not found. Install it from https://github.com/bridgecrewio/checkov"; \
	fi

# Run all security checks
security-checks: security-scan tfsec checkov
pre-commit: fmt validate lint
	@echo "Pre-commit checks completed successfully!"

# CI/CD pipeline
ci: init validate fmt lint test
	@echo "CI/CD pipeline completed successfully!" 
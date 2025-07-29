package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestLoadBalancerBasic(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars:         map[string]interface{}{
			// Add any variables if needed
		},
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get the load balancer ID
	loadBalancerID := terraform.Output(t, terraformOptions, "load_balancer_id")
	loadBalancerDNSName := terraform.Output(t, terraformOptions, "load_balancer_dns_name")

	// Verify the load balancer exists
	assert.NotEmpty(t, loadBalancerID)
	assert.NotEmpty(t, loadBalancerDNSName)

	// Wait for the load balancer to be available
	aws.WaitUntilElbIsAvailable(t, aws.GetDefaultRegion(t), loadBalancerID, 10, 30*time.Second)
}

func TestLoadBalancerAdvanced(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/advanced",
		Vars:         map[string]interface{}{
			// Add any variables if needed
		},
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	loadBalancerID := terraform.Output(t, terraformOptions, "load_balancer_id")
	loadBalancerDNSName := terraform.Output(t, terraformOptions, "load_balancer_dns_name")
	targetGroupARNs := terraform.OutputMap(t, terraformOptions, "target_group_arns")
	securityGroupID := terraform.Output(t, terraformOptions, "security_group_id")
	wafWebACLAssociationID := terraform.Output(t, terraformOptions, "waf_web_acl_association_id")

	// Verify the load balancer exists
	assert.NotEmpty(t, loadBalancerID)
	assert.NotEmpty(t, loadBalancerDNSName)

	// Verify target groups exist
	assert.NotEmpty(t, targetGroupARNs)
	assert.Contains(t, targetGroupARNs, "web")
	assert.Contains(t, targetGroupARNs, "api")

	// Verify security group exists
	assert.NotEmpty(t, securityGroupID)

	// Verify WAF association exists
	assert.NotEmpty(t, wafWebACLAssociationID)

	// Wait for the load balancer to be available
	aws.WaitUntilElbIsAvailable(t, aws.GetDefaultRegion(t), loadBalancerID, 10, 30*time.Second)
}

func TestLoadBalancerNetwork(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/network",
		Vars:         map[string]interface{}{
			// Add any variables if needed
		},
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	loadBalancerID := terraform.Output(t, terraformOptions, "load_balancer_id")
	loadBalancerDNSName := terraform.Output(t, terraformOptions, "load_balancer_dns_name")
	loadBalancerType := terraform.Output(t, terraformOptions, "load_balancer_type")
	targetGroupARNs := terraform.OutputMap(t, terraformOptions, "target_group_arns")

	// Verify the load balancer exists
	assert.NotEmpty(t, loadBalancerID)
	assert.NotEmpty(t, loadBalancerDNSName)
	assert.Equal(t, "network", loadBalancerType)

	// Verify target groups exist
	assert.NotEmpty(t, targetGroupARNs)
	assert.Contains(t, targetGroupARNs, "tcp")
	assert.Contains(t, targetGroupARNs, "tls")

	// Wait for the load balancer to be available
	aws.WaitUntilElbIsAvailable(t, aws.GetDefaultRegion(t), loadBalancerID, 10, 30*time.Second)
}

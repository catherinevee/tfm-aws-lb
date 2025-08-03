package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformLbBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/simple",
		Vars: map[string]interface{}{
			"name":               "terratest-lb",
			"environment":        "test",
			"load_balancer_type": "application",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	lbName := terraform.Output(t, terraformOptions, "load_balancer_name")
	assert.Equal(t, "terratest-lb", lbName)

	lbType := terraform.Output(t, terraformOptions, "load_balancer_type")
	assert.Equal(t, "application", lbType)

	internal := terraform.Output(t, terraformOptions, "load_balancer_internal")
	assert.Equal(t, "false", internal)
}

func TestTerraformLbInternalExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/internal-lb",
		Vars: map[string]interface{}{
			"name":               "terratest-internal-lb",
			"environment":        "test",
			"load_balancer_type": "application",
			"internal":           true,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	lbName := terraform.Output(t, terraformOptions, "load_balancer_name")
	assert.Equal(t, "terratest-internal-lb", lbName)

	internal := terraform.Output(t, terraformOptions, "load_balancer_internal")
	assert.Equal(t, "true", internal)
}

func TestTerraformLbCompleteExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"name":                       "terratest-complete-lb",
			"environment":                "test",
			"load_balancer_type":         "application",
			"enable_deletion_protection": true,
			"enable_http2":               true,
			"enable_wafv2":               true,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	lbName := terraform.Output(t, terraformOptions, "load_balancer_name")
	assert.Equal(t, "terratest-complete-lb", lbName)

	http2Enabled := terraform.Output(t, terraformOptions, "enable_http2")
	assert.Equal(t, "true", http2Enabled)
}

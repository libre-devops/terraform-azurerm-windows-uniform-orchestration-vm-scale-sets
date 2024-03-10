## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_os_calculator"></a> [os\_calculator](#module\_os\_calculator) | registry.terraform.io/libre-devops/linux-os-sku-calculator/azurerm | n/a |
| <a name="module_os_calculator_with_plan"></a> [os\_calculator\_with\_plan](#module\_os\_calculator\_with\_plan) | registry.terraform.io/libre-devops/linux-os-sku-with-plan-calculator/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_security_group.asg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group) | resource |
| [azurerm_linux_virtual_machine_scale_set.linux_vm_scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) | resource |
| [azurerm_marketplace_agreement.plan_acceptance_custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_marketplace_agreement.plan_acceptance_simple](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The admin password to be used on the VMSS that will be deployed. The password must meet the complexity requirements of Azure. | `string` | `""` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The admin username of the VM that will be deployed. | `string` | `"LibreDevOpsAdmin"` | no |
| <a name="input_asg_name"></a> [asg\_name](#input\_asg\_name) | Name of the application security group | `string` | n/a | yes |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list of user managed identity ids to be assigned to the VM. | `list(string)` | `[]` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | The Managed Service Identity Type of this Virtual Machine. | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_plan"></a> [plan](#input\_plan) | When a plan VM is used with a image not in the calculator, this will contain the variables used | `map(any)` | `{}` | no |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | Used for the settings block | `any` | n/a | yes |
| <a name="input_source_image_reference"></a> [source\_image\_reference](#input\_source\_image\_reference) | Whether the module should use the a custom image | `map(any)` | `{}` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | The public key to be added to the admin username | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | <pre>{<br>  "source": "terraform"<br>}</pre> | no |
| <a name="input_use_simple_image"></a> [use\_simple\_image](#input\_use\_simple\_image) | Whether the module should use the simple OS calculator module, default is true | `bool` | `true` | no |
| <a name="input_use_simple_image_with_plan"></a> [use\_simple\_image\_with\_plan](#input\_use\_simple\_image\_with\_plan) | If you are using the Windows OS Sku Calculator with plan, set this to true. Default is false | `bool` | `false` | no |
| <a name="input_vm_os_id"></a> [vm\_os\_id](#input\_vm\_os\_id) | The resource ID of the image that you want to deploy if you are using a custom image.Note, need to provide is\_windows\_image = true for windows custom images. | `string` | `""` | no |
| <a name="input_vm_os_offer"></a> [vm\_os\_offer](#input\_vm\_os\_offer) | The name of the offer of the image that you want to deploy. This is ignored when vm\_os\_id or vm\_os\_simple are provided. | `string` | `""` | no |
| <a name="input_vm_os_publisher"></a> [vm\_os\_publisher](#input\_vm\_os\_publisher) | The name of the publisher of the image that you want to deploy. This is ignored when vm\_os\_id or vm\_os\_simple are provided. | `string` | `""` | no |
| <a name="input_vm_os_simple"></a> [vm\_os\_simple](#input\_vm\_os\_simple) | Specify WindowsServer, to get the latest image version of the specified os.  Do not provide this value if a custom value is used for vm\_os\_publisher, vm\_os\_offer, and vm\_os\_sku. | `string` | `""` | no |
| <a name="input_vm_os_sku"></a> [vm\_os\_sku](#input\_vm\_os\_sku) | The sku of the image that you want to deploy. This is ignored when vm\_os\_id or vm\_os\_simple are provided. | `string` | `""` | no |
| <a name="input_vm_os_version"></a> [vm\_os\_version](#input\_vm\_os\_version) | The version of the image that you want to deploy. This is ignored when vm\_os\_id or vm\_os\_simple are provided. | `string` | `"latest"` | no |
| <a name="input_vm_plan"></a> [vm\_plan](#input\_vm\_plan) | Used for VMs which requires a plan | `set(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ss_id"></a> [ss\_id](#output\_ss\_id) | The name of the scale set |
| <a name="output_ss_name"></a> [ss\_name](#output\_ss\_name) | The name of the scale set |
| <a name="output_ss_principal_id"></a> [ss\_principal\_id](#output\_ss\_principal\_id) | Client ID of system assigned managed identity if created |
| <a name="output_unique_ss_id"></a> [unique\_ss\_id](#output\_unique\_ss\_id) | The id of the scale set |

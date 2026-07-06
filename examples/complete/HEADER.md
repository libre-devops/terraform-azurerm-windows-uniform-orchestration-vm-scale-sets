<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

The full appliable surface: an NSG with explicit allows above the DenyAllInbound baseline
(probes, app port, WinRM), explicit egress via a NAT gateway (subnets are private by default,
so the first-boot Chocolatey bootstrap depends on it), subnets carved by the subnet-calculator module (sequential,
non-overlapping, convention-named, dropped straight into the network module), a uniform Windows
scale set joined to a private load balancer backend pool with an Application Health extension,
automatic instance repair, an automatic OS upgrade policy, a WinRM HTTP listener, a scale-in
policy, termination notification, a data disk, a timezone, and accelerated networking. Spot with
spot_restore, rolling upgrades, unattend content, and Key Vault certificates are covered by the
mocked tests instead. The environment comes from the Terraform workspace (`terraform.workspace`),
not a variable. Run it with `just e2e complete`, which applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

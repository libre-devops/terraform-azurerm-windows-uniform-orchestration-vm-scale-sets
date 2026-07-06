# Post-plan sanity checks: informational (warn), they never fail an apply.

check "has_scale_sets" {
  assert {
    condition     = length(var.scale_sets) > 0
    error_message = "No scale sets are defined: the module call creates nothing."
  }
}

# Turning off automatic updates without another patching story is worth seeing. An automatic OS
# upgrade policy IS a patching story (Azure requires automatic updates off alongside it), so that
# combination stays quiet.
check "automatic_updates_optouts_are_visible" {
  assert {
    condition = alltrue([
      for s in values(var.scale_sets) :
      s.enable_automatic_updates || s.automatic_os_upgrade_policy != null
    ])
    error_message = "At least one scale set turns off automatic updates with no automatic OS upgrade policy: pair the opt-out with an explicit patching story."
  }
}

# Trusted Launch opt-outs are worth seeing too: every catalog image supports it.
check "trusted_launch_optouts_are_visible" {
  assert {
    condition     = alltrue([for s in values(var.scale_sets) : s.secure_boot_enabled && s.vtpm_enabled])
    error_message = "At least one scale set turns off secure boot or vTPM (Trusted Launch): the defaults are on for a reason."
  }
}

# Automatic instance repair without a health signal never repairs anything.
check "instance_repair_has_health_signal" {
  assert {
    # try() guards the null side: 1.9 evaluates both || operands.
    condition = alltrue([
      for s in values(var.scale_sets) :
      !try(s.automatic_instance_repair.enabled, false) || s.health_probe_id != null || anytrue([
        for e in values(s.extensions) : e.type == "ApplicationHealthWindows"
      ])
    ])
    error_message = "At least one scale set enables automatic_instance_repair without a health signal (health_probe_id or an ApplicationHealthWindows extension)."
  }
}

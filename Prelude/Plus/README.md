Prelude Plus
============
> These are files that contain functions that are not part of the core Prelude module, for one reason or another.

`Get-Screenshot`
----------------
> This function triggers Windows security since it is similar to [PowerShell Empire code](https://github.com/EmpireProject/Empire/blob/08cbd274bef78243d7a8ed6443b8364acd1fc48b/data/module_source/collection/Get-Screenshot.ps1). As a standalone cmdlet, if `Get-Screenshot` is blocked by Windows security, the impace will be isolated from the rest of the Prelude module.
# PSNativeCmdDevKit

[![Build Status](https://dev.azure.com/dsccommunity/PSNativeCmdDevKit/_apis/build/status/dsccommunity.PSNativeCmdDevKit?branchName=master)](https://dev.azure.com/dsccommunity/PSNativeCmdDevKit/_build/latest?definitionId=43&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/PSNativeCmdDevKit/43/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/PSNativeCmdDevKit/43/master)](https://dsccommunity.visualstudio.com/PSNativeCmdDevKit/_test/analytics?definitionId=43&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/PSNativeCmdDevKit?label=PSNativeCmdDevKit%20Preview)](https://www.powershellgallery.com/packages/PSNativeCmdDevKit/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSNativeCmdDevKit?label=PSNativeCmdDevKit)](https://www.powershellgallery.com/packages/PSNativeCmdDevKit/)

A set of functions for building PowerShell wrappers around native commands.

## Native Command Wrapper helper functions

Modules that wrap native executables commonly need to build argument lists,
combine standard error with standard output, parse line-oriented output, and
apply platform-specific elevation behavior.

You build the command and its parameters based on what you want to achieve, redirect the Error stream to the success stream, process the output with regex-fu, and desinterlace the error stream to have its own handling.

On Linux and macOS, wrappers may also need to apply `sudo` only to specific
commands or argument combinations.

This module centralizes those patterns so wrappers do not duplicate them.

## Scenarios

### Invoke Native Command

Whether you invoke `dpkg` on Debian or `choco.exe` on Windows, the same
argument-safe approach applies.

Build the parameters you wish to use, add the executable, redirect the STDERR to STDOUT and process those streams (separately).

As an example, on Linux you could wrap the `lsb_release --all` command.

```PowerShell
function Get-LsbRelease {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
    )

    $properties = Invoke-NativeCommand -Executable 'lsb_release' -Parameters '--all' |
        Get-PropertyHashFromListOutput -ErrorHandling {
            switch -Regex ($_) {
                'No\sLSB\smodules' { Write-Verbose $_ }
                Default            { Write-Error "$_" }
            }
        }

    [PSCustomObject]$properties | Add-Member -TypeName 'LsbRelease' -PassThru
}
```

`Invoke-NativeCommand` specifies the executable and its arguments. Add `-Sudo`
or `-SudoAs` on Linux or macOS when elevation is required.

The executable and each parameter are invoked as separate values. They are not
combined into PowerShell source code.

Sudo preference filters accept either `*` to match every parameter list or a
script block:

```PowerShell
Add-SudoPreferenceRule -Executable 'dpkg' `
    -ParameterFilterRule { $args -contains '--install' }
```

The supplied script block is retained and invoked directly. String expressions
are rejected and are never recompiled as PowerShell code.

## Security model

This module may be embedded in an Authenticode-signed parent module and execute
as trusted `FullLanguage` code on a WDAC/App Control enforced host. Public
functions therefore treat every caller-provided value as untrusted data.

- Executable names and arguments are never compiled as PowerShell source.
- Sudo filter script blocks are invoked as the original objects so a block
  created in `ConstrainedLanguage` remains constrained.
- String expressions are not accepted as sudo filters.

Review `.github/instructions/wdac-language-mode.instructions.md` when changing
command invocation, script-block handling, exports, nested modules, or signing.

## Building and testing

The repository uses Sampler `0.121.0-preview0001`.

```powershell
./build.ps1 -ResolveDependency -Tasks noop
./build.ps1 -Tasks build
./build.ps1 -Tasks test
./build.ps1 -Tasks hqrmtest
./build.ps1 -Tasks docs
./build.ps1 -Tasks pack
```

The Azure Pipelines matrix validates Windows PowerShell 5.1 and PowerShell 7 on
Windows, Linux, and macOS. The package workflow generates command reference
pages, combines them with hand-authored pages from `source/WikiSource`, and
packages `output/WikiContent.zip`. Successful release deployments publish that
content to the repository's GitHub wiki.

## Converting a list-formatted output to a Hash

In the example above, the output of the command is a list view of the properties retrieved:

```bash
gael@laptop:~$ lsb_release --all
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 18.04.4 LTS
Release:        18.04
Codename:       bionic
```

`Get-PropertyHashFromListOutput` parses key/value properties from standard
output.

The message `No LSB modules are available.` is actually coming from STDERR.

each line of the output that is not coming from STDERR, is of the form: `^\s*(?<property>[\w-\s]*):\s*(?<val>.*)`.
You can use a customised regex using the parameter `-Regex`.

When streaming invocation output to this function:
`Invoke-NativeCommand -Executable 'lsb_release' -Parameters '--all' |  Get-PropertyHashFromListOutput`

The command is creating a hashtable of Key/value properties, removing spaces and dashes, in this case the hashtable returned would be defined like this:

```PowerShell
@{
    DistributorID   = 'Ubuntu'
    Description     = 'Ubuntu 18.04.4 LTS'
    Release         = '18.04'
    Codename        = 'bionic'
}
```

Because `No LSB modules are available.` comes from standard error, it is not
parsed by the regular expression.
Instead, the `-ErrorHandling` scriptblock will process each line of STDERR.
In this case, the line matching the regex `No\sLSB\smodules` will be displayed on the verbose stream, while every other line comming from STDERR will be written on the error stream.

> Note: multi-line properties behave slightly differently.

When a property carries on to the second line, and does not match the regex, the entire line is added to the last property created.

For instance:
```bash
$ dpkg --status powershell
Package: powershell
Status: install ok installed
Priority: extra
Section: shells
Installed-Size: 154614
Maintainer: PowerShell Team <PowerShellTeam@hotmail.com>
Architecture: amd64
Version: 7.0.2-1.ubuntu.18.04
Depends: libc6, libgcc1, libgssapi-krb5-2, liblttng-ust0, libstdc++6, zlib1g, libssl1.0.0, libicu60
Description: PowerShell is an automation and configuration management platform.
 It consists of a cross-platform command-line shell and associated scripting language.
License: MIT License
Vendor: Microsoft Corporation
Homepage: https://microsoft.com/powershell
```

The `Description` property value is:
```
PowerShell is an automation and configuration management platform.
It consists of a cross-platform command-line shell and associated scripting language.
```

> Note: This bit of code could be improved, to look at the left padding of the previous property, and see if the padding increased.  
> PR welcomed

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

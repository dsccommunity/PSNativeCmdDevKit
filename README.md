# PSNativeCmdDevKit

[![Build Status](https://dev.azure.com/dsccommunity/PSNativeCmdDevKit/_apis/build/status/dsccommunity.PSNativeCmdDevKit?branchName=master)](https://dev.azure.com/dsccommunity/PSNativeCmdDevKit/_build/latest?definitionId=43&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/PSNativeCmdDevKit/43/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/PSNativeCmdDevKit/43/master)](https://dsccommunity.visualstudio.com/PSNativeCmdDevKit/_test/analytics?definitionId=43&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/PSNativeCmdDevKit?label=PSNativeCmdDevKit%20Preview)](https://www.powershellgallery.com/packages/PSNativeCmdDevKit/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSNativeCmdDevKit?label=PSNativeCmdDevKit)](https://www.powershellgallery.com/packages/PSNativeCmdDevKit/)

A set of functions to help develop "Native Command Wrapper" faster.

## Native Command Wrapper helper functions

When you create modules that wrap binary executables and parses their output, you follow a similar pattern.

You build the command and its parameters based on what you want to achieve, redirect the Error stream to the success stream, process the output with regex-fu, and desinterlace the error stream to have its own handling.

If you're on Linux or Mac, you might also want to handle Sudo when invoking those commands.
Some command can run without sudo or not, dependencing on the parameters used. Maybe an all or nothing approach is not the best, or maybe you want to let the user specify what other user to sudo as when running some commands.

This module tries to address these use case and avoid copying the same source code to different modules.

## Scenarios

### Invoke Native Command

Whether you cant to invoke `dpkg` on a Debian or `Choco.exe` on Windows, you will have the same approach.

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

The Invoke-NativeCommand tells which executable to invoke, and with what arguments.
In this example, we don't require sudo either, otherwise we
could have hadded the `-Sudo` parameter to `Invoke-NativeComand`.

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

The command `Get-PropertyHashFromListOutput` is a helper function to help parsing key/values properties coming from STDOUT.

The message `No LSB modules are available.` is actually coming from STDERR.

each line of the output that is not coming from STDERR, is of the form: `^\s*(?<property>[\w-\s]*):\s*(?<val>.*)`.
You can use a customised regex using the parameter `-Regex`.

When steaming the output of the invocation to this function like this:  
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

Because the line output `No LSB modules are available.` is 
coming from STDERR, it is not parsed by the regex.  
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

The Description property value here whould be
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

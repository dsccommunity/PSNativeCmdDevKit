using module Microsoft.PowerShell.NativeCommandProxy/src/Microsoft.PowerShell.NativeCommandProxy.psd1

[CmdletBinding()]
param(
    $first = ([int]::maxvalue),

    $command,

    $ProxyCommand = $(New-ProxyCommand -Verb Get -Noun ChocolateyCommandParameters)
)

if (!$ProxyCommand.OriginalName) {
    $ProxyCommand.OriginalName = 'choco'
}

$chocoParam = @()
if ($command) {$chocoParam =  @($command)}
$chocoParam +=  '--help'
Write-verbose "Choco $($chocoParam -join ' ')"
$chocohelp = choco $chocoParam  | select-Object -First $first

$section = $null
$TextInfo = (Get-Culture).TextInfo
$chocoCommands =  @()
$options = @{}

$chocohelp | % {
    switch -Regex ($_) {
        '^Commands$' {
            Write-Verbose "Starting to parse commands..."
            $section = 'commands_start'
            Write-Debug -Message "----------> Section: $section"

        }

        '^$' {
            if ($section -eq 'commands_start') {
                $section = 'commands'
                Write-Debug -Message "----------> Section: $section"
            }
            elseif ($section -eq 'commands') {
                $section = 'commands_stop'
                Write-Debug -Message "----------> Section: $section"
                if ($chocoCommands.Count -gt 1 -and $section -eq 'commands_stop') {
                    foreach ($chocoCommand in $chocoCommands) {
                        $ProxyCommand.Parameters.Add(
                            (New-ParameterInfo -Name $chocoCommand.cmd -OriginalName "--$($chocoCommand.cmd)")
                        )
                        . $PSScriptRoot\chocoHelpParser.ps1 -command $chocoCommand.cmd -ProxyCommand $ProxyCommand
                    }
                }
            }
            elseif($section = 'Options and Switches' -and $currentOptionName) {
                
                $currentOptionName = ''
            }
            else {
                Write-verbose "empty line"
            }
        }

        '\s\*\s(?<command>[^-]*)\s\-\s(?<cmdDesc>.*)'{
            if ($section -eq 'commands') {
                Write-verbose "command: '$($matches.command)' with description '$($matches.cmdDesc)'."
                $chocoCommands += @{cmd = $matches.command; descrition = $matches.cmdDesc}
            }
        }

        'Options and Switches' {
            if ($section -ne 'commands') {
                $section = 'Options and Switches'
                Write-Debug -Message "----------> Section: $section"
            }
        }

        '\s(?<short>\-[\w\?],)?\s*(?<long>--.*)' {
           
            $Paraname = $TextInfo.ToTitleCase(($matches.long -split '\,')[0]) -replace '-',''
            Write-Warning "$Paraname"
            $options[$Paraname] =''
            $currentOptionName = $Paraname
            break
        }

        '^\s{5,7}' {
            if ($currentOptionName) {
                $options[$currentOptionName] += $_.trim() + " "
            }
        }

        Default { Write-Debug $_ }
    }
}
# $options
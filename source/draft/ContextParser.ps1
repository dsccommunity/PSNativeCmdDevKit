[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true)]
    [object[]]
    $Line,

    [int]
    $First,

    $Contexts = @(
        @{
            Name               = 'ChocoVersion'
            Regex              = "Chocolatey v(?<version>[^\s]*)"
            # Property = 'version'
            NextContextTrigger = 'NumberOfLines'<# 'numberOfLine' ,'NewLine','NextContextRegex','outdent' #>
            NumberOfLines      = 1
            values             = 'version'
        }

        @{
            Name               = 'PageName'
            Regex              = "(?<PageName>[^\s]*)"
            NextContextTrigger = 'NumberOfLines'<# ,'NewLine','NextContextRegex','numberOfLine' #>
            NumberOfLines      = 1
            values             = 'PageName'
        }

        @{
            Name               = 'Description'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name               = 'Note'
            Regex              = '^NOTE:'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name               = 'Usage'
            Regex              = '^Usage$'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name               = 'Examples'
            Regex              = '^Examples$'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name               = 'Exit Codes'
            Regex              = '^Exit\sCodes'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name               = 'See It in Action'
            Regex              = '^See It In Action$'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name               = 'AlternativeSources'
            Regex              = 'Alternative\sSources$'
            NextContextTrigger = 'NextContextRegex'
        }

        @{
            Name  = 'Options and Switches'
            Regex = '^Options\sand\sSwitches$'
        }
    )
)

begin
{
    $ContextIndex = 0
    $OutputLineNumber = -1
    $ContextLineCounters = @{}
    $ParsedObject = @{}
    # Chocolatey v(?<version>[^\s]*).*^
    # ^(?<page>.*)$
    # \\\\\
    # DESC
    # NOTE:
    # USAGE
    # Examples
    # NOTE
    # EXIT CODES
}

process
{
    $Line | Foreach-Object {
        $currentContext = $Contexts[$ContextIndex]
        $OutputLineNumber++
        Write-Debug "[L#$OutputLineNumber] Processing line $OutputLineNumber "
        Write-Debug "output: '$_'"

        #Region evaluate context trigger to decide current context
        if (-not $_.Trim() -and $currentContext.NextContextTrigger -eq 'EmptyLine')
        {
            # Empty line & change context on empty line
            $previousContext = $currentContext
            $ContextIndex++
            $currentContext = $Contexts[$ContextIndex]
            Write-Debug "Moving to context $($CurrentContext.Name)"
            $ContextLineCounters[$currentContext.Name] = 1
            Write-Verbose "-- context: $($CurrentContext.Name) [L#1]"
        }
        elseif ($currentContext.NextContextTrigger -eq 'NumberOfLines')
        {
            # Current context changes when we've processed a number of lines in this context
            if ($ContextLineCounters.keys -contains $CurrentContext.Name)
            {
                if ($contextLineCounters[$CurrentContext.Name] -lt $currentContext.NumberOfLines)
                {
                    # Not reached the number configured, add 1 to the current context line counter
                    $contextLineCounters[$CurrentContext.Name]++
                    Write-Debug "-- context: $($CurrentContext.Name) [L#$($contextLinecounters[$CurrentContext.Name])]"
                }
                elseif ($contextLineCounters[$CurrentContext.Name] -ge $currentContext.NumberOfLines)
                {
                    # reach the number of lines for this context. Switch context and reset counter.
                    $previousContext = $currentContext
                    $ContextIndex++
                    $currentContext = $Contexts[$ContextIndex]
                    $ContextLineCounters[$previousContext.Name] = $null
                    Write-Debug "Moving to context $($CurrentContext.Name)"
                    $ContextLineCounters[$currentContext.Name] = 1
                    Write-Verbose "-- context: $($CurrentContext.Name) [L#1]"
                }
            }
            else
            {
                # In case the counter does not exist, create it and set to 1st line
                Write-Verbose "-- context: $($CurrentContext.Name) [L#1]"
                $ContextLineCounters[$currentContext.Name] = 1
            }
        }
        elseif ($currentContext.NextContextTrigger -eq 'NextContextRegex' -and ($_ -match ($Contexts[($ContextIndex + 1)]).Regex))
        {
            # If the trigger to change context is the next context regex, and it matches, move to next context
            $previousContext = $currentContext
            $ContextIndex++
            $CurrentContext = $Contexts[$ContextIndex]
            Write-Debug "Moving to context $($CurrentContext.Name)"
            $ContextLineCounters[$previousContext.Name] = $null
            $ContextLineCounters[$currentContext.Name] = 1
            Write-Verbose "-- context: $($CurrentContext.Name) [L#1]"
        }
        else
        {
            # No trigger to switch to next context found, just keep counting lines for this context.
            $ContextLineCounters[$currentContext.Name]++
            Write-Debug "-- context: $($CurrentContext.Name) [L#$($ContextLineCounters[$currentContext.Name])]"
        }
        #endregion

        Write-Debug "Context '$($currentContext.Name)'"

        # Processing (TODO)
        Write-Host $_ -ForegroundColor green


        Write-Debug "[L#$OutputLineNumber] End of line processing"
        Write-Debug " "
    }
}

end
{

}

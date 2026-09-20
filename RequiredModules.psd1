@{
    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = 'latest'
    ModuleBuilder               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = @{
        version    = '0.121.0-preview0001'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    'Sampler.GitHubTasks'       = 'latest'
    MarkdownLinkCheck           = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    'DscResource.DocGenerator'  = 'latest'
    Plaster                     = 'latest'
    platyPS                     = 'latest'
    xDscResourceDesigner        = 'latest'
    'Microsoft.PowerShell.PSResourceGet' = 'latest'
}

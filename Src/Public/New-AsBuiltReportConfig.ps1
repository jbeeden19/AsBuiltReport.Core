function New-AsBuiltReportConfig {
    <#
    .SYNOPSIS  
        Creates JSON configuration files for individual As Built Reports.
    .DESCRIPTION
        Creates JSON configuration files for individual As Built Reports.
    .PARAMETER Report
        Specifies the type of report configuration to create.
    .PARAMETER Path
        Specifies the path to create the report JSON configuration file.
    .PARAMETER Name
        Specifies the name of the report JSON configuration file.
        If Name is not specified, a JSON configuration file will be created with a default name AsBuiltReport.<Vendor>.<Product>.json
    .PARAMETER Overwrite
        Specifies to overwrite any existing report JSON configuration file
    .EXAMPLE
        Creates a report configuration file for VMware vSphere, named 'vSphere_Report_Config' in 'C:\Reports' folder. 
        New-AsBuiltReportConfig -Report VMware.vSphere -Path 'C:\Reports' -Name 'vSphere_Report_Config'
    .EXAMPLE
        Creates a report configuration file for Nutanix Prism Central, named 'AsBuiltReport.Nutanix.PrismCentral' in 'C:\Reports' folder, overwriting any existing file. 
        New-AsBuiltReportConfig -Report Nutanix.PrismCentral -Path 'C:\Reports' -Overwrite
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Please provide the name of the report to generate the JSON configuration for'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                $InstalledReportModules = Get-Module -Name "AsBuiltReport.*" -ListAvailable | Where-Object { $_.name -ne 'AsBuiltReport.Core' } | Sort-Object -Property Version -Descending | Select-Object -Unique
                $ValidReports = foreach ($InstalledReportModule in $InstalledReportModules) {
                    $NameArray = $InstalledReportModule.Name.Split('.')
                    "$($NameArray[-2]).$($NameArray[-1])"
                }
                if ($ValidReports -contains $_) {
                    $true
                } else {
                    throw "Invalid report type specified! Please use one of the following [$($ValidReports -Join ', ')]"
                }
            })]
        [String] $Report,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Please provide the path to save the JSON configuration file'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Path,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the name of the JSON configuration file'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Used to overwrite the destination file if it exists'
        )]
        [ValidateNotNullOrEmpty()]
        [Switch] $Overwrite
    )

    # Test to ensure the path the user has specified does exist
    if (!(Test-Path -Path $Path)) {
        Write-Error "The Path $Path does not exist. Please create the folder and re-run New-AsBuiltReportConfig"
        break
    }
    # Find the root folder where the module is located for the report that has been specified
    try {
        $Module = Get-Module -Name "AsBuiltReport.$Report" -ListAvailable | Where-Object { $_.name -ne 'AsBuiltReport.Core' } | Sort-Object -Property Version -Descending | Select-Object -Unique
        if ($Name) {
            if (!(Test-Path -Path "$($Path)\$($Name).json")) {
                Copy-Item -Path "$($Module.ModuleBase)\$($Module.Name).json" -Destination "$($Path)\$($Name).json"
                Write-Output "$Name JSON configuration file created in $Path"
            } elseif ($Overwrite) {
                Copy-Item -Path "$($Module.ModuleBase)\$($Module.Name).json" -Destination "$($Path)\$($Name).json" -Force
                Write-Output "$Name JSON configuration file created in $Path"
            } else {
                Write-Error "$Name filename already exists in $Path"
            }
        } else {
            if (!(Test-Path -Path "$($Path)\$($Module.Name).json")) {
                Copy-Item -Path "$($Module.ModuleBase)\$($Module.Name).json" -Destination $Path
                Write-Output "$($Module.Name) JSON configuration file created in $Path"
            } elseif ($Overwrite) {
                Copy-Item -Path "$($Module.ModuleBase)\$($Module.Name).json" -Destination $Path -Force
                Write-Output "$($Module.Name) JSON configuration file created in $Path"
            } else {
                Write-Error "$($Module.Name).json report configuration already exists in $Path"
            }
        }
    } catch {
        Write-Error $_
    }
}

Register-ArgumentCompleter -CommandName 'New-AsBuiltReportConfig' -ParameterName 'Report' -ScriptBlock {
    param (
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameter
    )

    $InstalledReportModules = Get-Module -Name "AsBuiltReport.*" -ListAvailable | Where-Object { $_.name -ne 'AsBuiltReport.Core' } | Sort-Object -Property Version -Descending | Select-Object -Unique
    $ValidReports = foreach ($InstalledReportModule in $InstalledReportModules) {
        $NameArray = $InstalledReportModule.Name.Split('.')
        "$($NameArray[-2]).$($NameArray[-1])"
    }

    $ValidReports | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
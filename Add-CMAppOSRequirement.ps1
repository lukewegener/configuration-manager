Function Add-CMAppOSRequirement {

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlResultObject]$CMApplication,
        [Parameter(Mandatory)]
        [Hashtable]$AddRequirement
    )
    
    Process {

        foreach ($thisApp in $CMApplication) {

            $appXml = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($thisApp.SDMPackageXML,$true)
            $dts = $appXml.DeploymentTypes

            $appChangeRequirement = $false
            
            foreach ($dt in $dts) {

                foreach($requirement in $dt.Requirements) {

                    if($requirement.Expression.gettype().name -eq 'OperatingSystemExpression') {

                        if ($requirement.Name -Notlike "*$($newRequirement.Name)*" ) {

                            $appChangeRequirement = $true
                            
                            Write-Host "$($thisApp.LocalizedDisplayName) has a missing OS requirement, appending value to it"
                            $requirement.Expression.Operands.Add($newRequirement.Operand)
                            $requirement.Name = [regex]::replace($requirement.Name, '(?<=Operating system One of {)(.*)(?=})', "`$1, $($newRequirement.Name)")
                            $null = $dt.Requirements.Remove($requirement)
                            $requirement.RuleId = "Rule_$([guid]::NewGuid())"
                            $null = $dt.Requirements.Add($requirement)
                            Break
                        }
                    }
                }
            }

            if ($appChangeRequirement) {

                $thisApp.SDMPackageXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($appXml, $True)
                $thisApp.put()
                $t = Set-CMApplication -InputObject $thisApp -PassThru
            }
        }
    }
}

# Example use. Get the app(s), define the requirement, pipe the app(s) to the function...

#$app = Get-CMApplication -Name 'Application Name'

#$newRequirement = @{
#    Name = 'All Windows Server 2022 and higher (64-bit)'
#    Operand = 'Windows/All_x64_Windows_Server_2022_and_higher'
#}

#$apps | Add-CMAppOSRequirement -AddRequirement $newRequirement
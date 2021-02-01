Function Clear-OperationCollection {
<# 
.SYNOPSIS
Cancel operations which are currently in EXECUTING status

.EXAMPLE
Clear-OperationCollection -Device 12345

Set all executing operations for device id 12345 to FAILED

.OUTPUTS
[Operation[]]
#>
    [cmdletbinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "High"
    )]
    Param(
        # Device
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [object[]] $Device,

        # Operation status
        [ValidateSet(
            "EXECUTING",
            "PENDING"
        )]
        [string] $Status = "EXECUTING",

        # Failure reason. Defaults to "Manually cancelled"
        [string] $FailureReason = "Manually cancelled",

        # Don't prompt for confirmation
        [switch] $Force
    )
    DynamicParam { PSc8y\Get-ClientCommonParameters -Type "Collection" -BoundParameters $PSBoundParameters }
    Begin {
        $CollectionParameters = @{} + $PSBoundParameters
        $null = $CollectionParameters.Remove("FailureReason")
        $null = $CollectionParameters.Remove("Force")
        $null = $CollectionParameters.Remove("WhatIf")
        $null = $CollectionParameters.Remove("Device")
        $null = $CollectionParameters.Remove("Status")
    }
    Process {
        foreach ($iDevice in (PSc8y\Expand-Device $Device)) {

            [array] $operations = PSc8y\Get-OperationCollection `
                -Device $iDevice `
                -Status $Status `
                -WhatIf:$false `
                @CollectionParameters
            
            if ($operations.Count -gt 0) {
                if (!$Force -and
                    !$WhatIfPreference -and
                    !$PSCmdlet.ShouldProcess(
                        (PSc8y\Get-C8ySessionProperty -Name "tenant"),
                        ("Cancelling {0} $Status operation/s on device [{1} ({2})]" -f @(
                            $operations.Count,
                            $iDevice.name,
                            $iDevice.id
                            ))
                    )) {
                    continue
                }
                $operations | PSc8y\Update-Operation `
                    -Status "FAILED" `
                    -FailureReason:$FailureReason `
                    -Force
            } else {
                Write-Warning ("Device [{0} ({1})] does not have any operations in [$Status] status" -f @(
                    $iDevice.name,
                    $iDevice.id
                ))
            }
        }
    }
}
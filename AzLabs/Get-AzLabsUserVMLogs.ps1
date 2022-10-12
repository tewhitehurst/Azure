[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
	[Parameter(Mandatory=$false)]
	[string]$SubscriptionID = '',
	
	[Parameter(Mandatory=$true)]
	[string]$ResourceGroup,
	
	[Parameter(Mandatory=$true)]
	[string]$LabName,
	
	[Parameter(Mandatory=$true)]
	[string]$UserEmail,
	
	[Parameter(Mandatory=$false, ParameterSetName='StartDays')]
	[Parameter(Mandatory=$false, ParameterSetName='EndDays')]
	[Parameter(Mandatory=$false, ParameterSetName='Default')]
	[int]$Days = 7,
	
	[Parameter(Mandatory=$false, ParameterSetName='StartEnd')]
	[Parameter(Mandatory=$false, ParameterSetName='EndDays')]
	[datetime]$EndTime = (Get-Date),
	
	[Parameter(Mandatory=$false, ParameterSetName='StartEnd')]
	[Parameter(Mandatory=$false, ParameterSetName='StartDays')]
	[datetime]$StartTime = $EndTime.AddDays($Days * -1),
	
	[Parameter(Mandatory=$False)]
    [Switch]$SimpleLogs
)

###################################################################################################
#
# Parameter processing
#

if ($PsCmdlet.ParameterSetName -eq "StartDays") {
	$EndTime = $StartTime.AddDays($Days)
}
elseif ($PsCmdlet.ParameterSetName -eq "EndDays") {
	$StartTime = $EndTime.AddDays($Days * -1)
}
elseif ($PsCmdlet.ParameterSetName -eq "Default") {
	$EndTime = Get-Date
	$StartTime = $EndTime.AddDays($Days * -1)
}
else {
	# Do Nothing
}

###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Hide any progress bars, due to downloads and installs of remote components.
$ProgressPreference = "SilentlyContinue"

# Ensure we set the working directory to that of the script.
Push-Location $PSScriptRoot

# Discard any collected errors from a previous execution.
$Error.Clear()

# Configure strict debugging.
Set-PSDebug -Strict

###################################################################################################
#
# Handle all errors in this script.
#

trap {
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $Error[0].Exception.Message
    if ($message) {
        Write-Host -Object "`nERROR: $message" -ForegroundColor Red
    }

    Write-Host "`nThe script failed to run.`n"

    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################
#
# Main execution block.
#

try {
	# Set subscription context this is only necessary if you have access to more than one Azure Subscription
	Write-Host "Setting subscription..."
	
	if ($SubscriptionId) {$null = Set-AzContext -SubscriptionId $SubscriptionId}

	# Connect to AzureAD to enable object lookup
	Write-Host "Connecting to AzureAD..."
	# Check for Cloud Shell
	if ($env:AZUREPS_HOST_ENVIRONMENT) {
		# Import AzureAD Preview and connect using correct tenant for cloud shell
		Import-Module AzureAD.Standard.Preview
		$null = AzureAD.Standard.Preview\Connect-AzureAD -Identity -TenantID $env:ACC_TID
	}
	else {
		# Import AzureAD and connect - this should launch a login GUI
		Import-Module AzureAD
		Connect-AzureAD
	}

	# Get the Lab VM associated with the provided userEmail
	Write-Host "Retrieving VM info for $($UserEmail)..."
	$labVM = Get-AzLabServicesUser -ResourceGroupName $ResourceGroup -LabName $LabName | ?{$_.Email -eq $UserEmail} | Get-AzLabServicesUserVM

	# Get current date+time
	$timeNow = Get-Date

	# Retrive logs for the Lab VM
	Write-Host "Retrieving activity logs for VM ID $($labVM.Name)..."
	$vmLogs = Get-AzLog -StartTime $StartTime -EndTime $EndTime -ResourceId $labVM.Id -WarningAction SilentlyContinue

	# Check SimpleLogs switch and, if specified, create simplified log entries and append to array
	if ($SimpleLogs) {
		$basicLogs = @()
		$vmLogs | %{
			if ($_.Caller -notlike '*@*') {
				$callerId = (Get-AzureADObjectByObjectId -ObjectIds $_.Caller).DisplayName
			}
			else {
				$callerId = $_.Caller
			}
			
			$basicLogs += [PSCustomObject]@{
				Operation = $_.OperationName
				TimeStamp = $_.EventTimeStamp
				Caller = $callerId
				Status = $_.Status
				Event = $_.EventName
			}
		}
		
		# Return the basic logs array
		Write-Host "Done!"
		return ($basicLogs)
	}
	else {
		# return the full (raw) logs array
		Write-Host "Done!"
		return ($vmLogs)
	}
}
finally {	
    # Restore system to state prior to execution of this script.
    Pop-Location
}
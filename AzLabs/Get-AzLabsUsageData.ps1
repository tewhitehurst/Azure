[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)]
	[string]$SubscriptionId = '',
	
	[Parameter(Mandatory=$true)]
	[string]$ResourceGroup,
	
	[Parameter(Mandatory=$true)]
	[string]$LabName,
	
	[Parameter(Mandatory=$true)]
	[int]$InferredUsers = 0,

	[Parameter(Mandatory=$true)]
	[int]$EstimateUsers = 50
)

# Set subscription context this is only necessary if you have access to more than one Azure Subscription
if ($SubscriptionId) {$null = Set-AzContext -SubscriptionId $SubscriptionId}

# Get the Lab Users
$labUsers = Get-AzLabServicesUser -ResourceGroupName $ResourceGroup -LabName $LabName

$usageHours = 0
$labUsers | %{$usageHours += $_.TotalUsage.TotalHours}

$usageStats = $labUsers.TotalUsage.TotalHours | Measure-Object -AllStats
$usageStatsAdj = (($labUsers | ?{$_.TotalUsage.TotalHours -gt 0}).TotalUsage.TotalHours) | Measure-Object -AllStats

$inferredUsage = $inferredUsers * $usageStats.Maximum
$inferredAvg = ($usageStats.Sum + $inferredUsage) / ($usageStats.Count + $inferredUsers)
$inferredAvgAdj = ($usageStatsAdj.Sum + $inferredUsage) / ($usageStatsAdj.Count + $inferredUsers)
$estUsage = @(($usageStats.Average * $EstimateUsers), ($usageStatsAdj.Average * $EstimateUsers)) | Measure-Object -AllStats

Write-Output ""
Write-Output "Lab Name: $LabName"
Write-Output "Resource Group: $ResourceGroup"
Write-Output "Subscription Id: $SubscriptionId"
Write-Output ""
Write-Output "Total users in lab: $($usageStats.Count)"
Write-Output "Users with usage: $($usageStatsAdj.Count)"
Write-Output "Maximum (per user) usage: $([math]::Round($($usageStats.Maximum),2)) hours"
Write-Output "Average usage: $([math]::Round($($usageStats.Average),2)) hours"
Write-Output "Adjusted average usage: $([math]::Round($($usageStatsAdj.Average),2)) hours"
Write-Output ""
Write-Output "User to infer: $InferredUsers"
Write-Output "Inferred usage: $([math]::Round($inferredUsage,2)) hours"
Write-Output "Inferred average usage: $([math]::Round($inferredAvg,2)) hours"
Write-Output "Inferred adjusted average usage: $([math]::Round($inferredAvgAdj,2)) hours"
Write-Output ""
Write-Output "Users to estimate: $EstimateUsers"
Write-Output "Estimated Usage: $([math]::Round($($estUsage.Minimum),2)) hours to $([math]::Round($($estUsage.Maximum),2)) hours"

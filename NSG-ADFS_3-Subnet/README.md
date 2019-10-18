# NSGs for 3-Subnet ADFS Architectures
This Template will deploy 3 Network Security Groups - one to attach to each of the 2 subnets in the 3-subnet ADFS Architecture:
- ADDS / IdM (Identity Management) Subnet
- ADFS Server Subnet
- WAP Server Subnet

The template utilizes default values for NSG names and subnet, virtual network, and on-premises address ranges.  The NSG names can be customized as desired and all network/subnet address ranges should be updated to represent the correct values for the deployment environment.  See the following notes:
- **ADDS Subnet NSG_Name** should be attached to the subnet containing Active Directory Domain Services Domain Controllers; this is often referred to as the Identity Management (IdM) subnet.  The default address range assigned is **10.251.251.0/25**.
- **ADFS Subnet NSG_Name** should be attached to the subnet containing the ADFS Servers.  The default address range assigned is **10.251.251.128/26**.
- **WAP Subnet NSG_Name** should be attached to the subnet containing the ADFS WAP (Proxy) Servers.  The default address range assigned is **10.251.251.192/26**.
- **On Premises Address Range** allows you to specify one or more on-premises network address ranges (in CIDR format) that will be trusted for access to the ADDS and ADFS subnets, including RDP.
- **Azure Virtual Network Address Range** allows you to specify one or more Azure virtual network subnet address ranges (in CIDR format) that will be trusted for access to the ADDS and ADFS subnets, including RDP.

## Visualize & Deploy
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Ftewhitehurst%2FAzure%2Fmaster%2FNSG-ADFS_3-Subnet%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftewhitehurst%2FAzure%2Fmaster%2FNSG-ADFS_3-Subnet%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>

## Disclaimer
*Any scripts, code or templates contained herein are not supported under any Microsoft standard support program or service.  The script, code or template is provided AS-IS without warranty of any kind.  Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the scripts, code or template(s) and associated documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script or code be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the script or documentation, even if Microsoft has been advised of the possibility of such damages.*



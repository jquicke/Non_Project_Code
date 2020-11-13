## GetWindowsVersion.ps1
# Enter the filesystem location of your text file of server host names here (host names should be one per line)
$server_list = "C:\powershell\scripts\Servers.txt";

# Don't change anything below this line

if (!(Test-Path -Path $server_list)) {
	Write-Output "Servers.txt file does not exist";
	exit;
}
else {
	foreach ($i in Get-Content $server_list) {
		if ($i.StartsWith("##")) {
			Write-Output $i;
			[Environment]::NewLine;
		}	
		else {
			$ping_result = (Get-WmiObject Win32_PingStatus -Filter "Address = '$i'").StatusCode;
			if ($ping_result = 1) {
				$i +"`n"+ "================================"; 
				Get-WmiObject Win32_OperatingSystem -computername $i | select Caption;
				[Environment]::NewLine;
			}
			else { 
				Write-Output "Server $i is not pingable"; 
			}
		}		
	}
}

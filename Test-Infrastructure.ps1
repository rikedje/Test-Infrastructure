
param (
    $File
)

<#



#>

function Write-OK {
    Write-Host "OK" -ForegroundColor Black -BackgroundColor Green
}

function Write-Failed {
    Write-Host "FAILED" -ForegroundColor White -BackgroundColor Red
}

function Test-Ping {
    param($ComputerName)
    Write-Host "PING: $ComputerName = " -NoNewline
    if(Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue) {
        Write-OK
    } else {
        Write-Failed
    }
}

function Test-HttpGet {
    param($Url)
    Write-Host "HTTP-GET: $Url = " -NoNewline
    try {
        Invoke-WebRequest -Uri $Url -UseDefaultCredentials -ErrorAction SilentlyContinue | Out-Null
        Write-Ok
    } catch {
        Write-Failed 
    }
}

function Test-FileShare {
    param($Path)
    Write-Host "FILESHARE: $Path = " -NoNewline
    if(Test-Path -Path $Path ) {
        Write-OK
    } else {
        Write-Failed
    }
}

function Test-SqlConnection {
    param($Connectionstring)
    
    Write-Host "SQLSERVER: $Connectionstring = " -NoNewline
    try {

        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $Connectionstring
        #$SqlConnection.ConnectionTimeout = 10

        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = "SELECT COUNT(*) FROM SYSOBJECTS;"
        $SqlCmd.Connection = $SqlConnection

        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd

        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet) | Out-Null
     
        $DataSet.Tables[0] | Out-Null
    
        $SqlConnection.Close()
    
        # Cleanup
        $dataset.dispose()
        $sqlconnection.dispose()
        $sqladapter.dispose()
        $sqlcmd.dispose()
        $sqlquery = ""
        
        Write-OK

    } catch {
        Write-Failed
    }
}

function Test-Dns {
    param($HostName)
    
    try {
        Write-Host "DNS: $HostName = " -NoNewline
        [system.Net.DNS]::resolve($HostName) | Out-Null
        Write-OK
    } catch {
        Write-Failed
    }
}


function Test-TcpPort {
    param($Endpoint, $Port)
    try {
        Write-Host "TCP: $EndPoint : $Port = " -NoNewline
        $conn = New-Object Net.Sockets.TcpClient $Endpoint, $Port
        if($conn.Connected) {
            Write-OK
        } else {
            Write-Failed
        }
        $conn.Close()
    } catch {
        Write-Failed
    }
}


[xml]$xml = Get-Content $File
$xml.tests.ChildNodes | % {
    if($_.type -eq "ping") { Test-Ping -ComputerName $_.host }
    if($_.type -eq "http-get") { Test-HttpGet -Url $_.url }
    if($_.type -eq "fileshare") { Test-FileShare $_.path }
    if($_.type -eq "sqlserver") { Test-SqlConnection $_.connectionstring }
    if($_.type -eq "dns") { Test-Dns -HostName $_.host}
    if($_.type -eq "tcp") { Test-TcpPort -EndPoint $_.host -Port $_.port }
}

# Spara resultat till fil
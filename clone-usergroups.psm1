<#
.SYNOPSIS

Clones group membership of a user
.DESCRIPTION

Clones the group membership of a user to another user
.PARAMETER computername

Here, the dotted keyword is followed by a single parameter name. Don't precede that with a hyphen. The following lines describe the purpose of the parameter:
.PARAMETER source-user
User from which to get the groups from.

.PARAMETER dest-user
User to apply the group membership to.

.PARAMETER force
Supresses confirmation on each group add.

.EXAMPLE
Clone-UserGroups -srcuser "myuser@mydomain.edu" "yourusers@mydomain.edu"

#>

function Get-UserGroups
    {
    param(
    $user,
    [array]$domains
    )
    foreach ($d in $domains)
        {
        try
            {
            $aduser += get-aduser $user -server $d -Properties MemberOf
            }
        catch
            {
            Write-Verbose -Message "$user does not exist in $d"
            }
        }
    if ($aduser -ne $null)
        {
        foreach ($a in $aduser)
            {
            Write-Verbose -Message "$user exists in $d"
            }
        }
    elseif ($aduser -eq $null)
        {
        Write-Error -Exception "Unable to locate the domain account for $user in $($domain | % { ",  $_"} )." 
        }
    return $aduser
    }

function Add-ADGroupMembership
    {
    param(
    $Source,
    $Destination
    )
    foreach ($S in $Source.MemberOf)
        {
        try
            {
            switch($force)
                {
                'True'
                    {
                    Add-ADGroupMember -Identity $S -Members $Destination
                    }
                'False'
                    {
                    Add-ADGroupMember -Identity $S -Members $Destination -Confirm
                    }
                }
            }
        catch
            {
            Write-Warning "Offending goup $S"
            Write-Warning "Exception: $_.Exception.Message"
            }
        }
    }

function Print-GroupMembership
    {
    param(
    $User
    )
    foreach ( $U in $User.Memberof)
        {
        Write-host $U
        }
    }

function Clone-UserGroups
    {
    param(
        [ValidatePattern("\A[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z")]
        [string]$srcuser,
        [ValidatePattern("\A[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z")]
        [string]$destuser,
        [switch]$force
        )
    $InformationPreference = "Continue"
    $VerbosePreference = "Continue"
    $DebugPreference = 'Continue'
    $ErrorActionPreference= 'Stop'

    $Force = $force
    $srcad = Get-UserGroups -user $srcuser.split('@')[0] -domains @($($srcuser.split('@')[1]))
    $dstad = Get-UserGroups -user $destuser.split('@')[0] -domains @($($destuser.split('@')[1]))
    Write-Host "Existing Group Membership for Source User ($srcuser)" -ForegroundColor Yellow
    Print-GroupMembership $srcad
    Write-Host "`r`n"
    Write-Host "Existing Group Membership for Destination User ($destuser)" -ForegroundColor Yellow
    Print-GroupMembership $dstad
    Add-ADGroupMembership -Source $srcad -Destination $dstad
    Start-Sleep -s 5
    $new_dstad = Get-UserGroups -user $destuser.split('@')[0] -domains @($($destuser.split('@')[1]))
    Write-Host "New Group Membership for Destination User ($destuser)" -ForegroundColor Yellow
    Print-GroupMembership $new_dstad
    }

Export-ModuleMember -Function Clone-UserGroups
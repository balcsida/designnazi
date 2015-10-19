function Remove-Font {
    # created by Dr. Tobias Weltner, MVP PowerShell
    # please keep this notice
    # use code freely at your own risk
    # looking for quality PowerShell trainings? 
    # drop me a line: tobias.weltner@scriptinternals.de
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $FileName
    )

    function Test-Admin {
	    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	    $prp = new-object System.Security.Principal.WindowsPrincipal($wid)
	    $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	    $prp.IsInRole($adm)
    }

	function Remove-FontFromRegistry($FileName) {
        $Path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
		$key = Get-Item $Path
		$props = @($key.GetValueNames() | 
		    Where-Object { $key.GetValue($_) -eq $FileName }) 

		Remove-ItemProperty -Path $Path -Name $props
        Write-Warning ('Removed these registry values: {0}' -f ($props -join ', '))
	}

    if (!(Test-Admin)) {
        Write-Warning 'Uninstalling Fonts Requires Admin Privileges. Launch Again in Elevated Shell'
        break
    }


	$API = @'
using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;

namespace WinAPI
{
    public class Font
    {
        private static IntPtr HWND_BROADCAST = new IntPtr(0xffff);
        
        [DllImport("gdi32.dll")]
        static extern int RemoveFontResource(string lpFileName);

        [return: MarshalAs(UnmanagedType.Bool)]
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        public static int RemoveFont(string fontFileName) {
            try 
            {
                int retVal = RemoveFontResource(fontFileName);
                bool posted = PostMessage(HWND_BROADCAST, 0x001D, IntPtr.Zero, IntPtr.Zero);
                return retVal;
            }
            catch
            {
                return 0;
            }
        }
    }
}
'@
	Add-Type $API

	try
	{
        $ErrorActionPreference = 'Stop'
		$FilePath = Join-Path ([system.environment]::getfolderpath('Font')) $fileName

        if ((Test-Path $FilePath) -eq $false) {
            Write-Warning "File '$FilePath' does not exist"
            break
           }
		$retVal = [WinAPI.Font]::RemoveFont($FilePath)
		if ($retVal -ne 0) 
		{
			Remove-FontFromRegistry $FileName
            takeown.exe /F $filepath 2>&1 > $null
            Write-Warning "Ownership taken for ""$FilePath"""
			Remove-Item $FilePath -Force
            Write-Warning "Removed file ""$FilePath"""
		}
	}
	catch {
		Write-Warning $_
	}
}

Remove-Font comic.ttf
Remove-Font comicbd.ttf
Remove-Font comicz.ttf
Remove-Font comici.ttf

# call like this:
# Remove-Font adler_,ttf

BeforeAll {
    $RepoRoot = Split-Path -Path $PSScriptRoot -Parent
    $PolicyFiles = Get-ChildItem -Path (Join-Path $RepoRoot 'Policies') -Filter '*.json' -Recurse
    $PersonaFiles = Get-ChildItem -Path (Join-Path $RepoRoot 'Config/Personas') -Filter '*.psd1'
}

Describe 'Policy JSON structure' {

    It 'Every policy file is valid JSON' {
        foreach ($File in $PolicyFiles) {
            { Get-Content -Path $File.FullName -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    It 'Every policy carries a _metadata block' {
        foreach ($File in $PolicyFiles) {
            $Json = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            $Json._metadata | Should -Not -BeNullOrEmpty -Because "$($File.Name) is missing _metadata"
        }
    }

    It 'Every _metadata block declares a tier of L1 or L2' {
        foreach ($File in $PolicyFiles) {
            $Json = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            $Json._metadata.tier | Should -BeIn @('L1', 'L2') -Because "$($File.Name) has an unexpected tier value"
        }
    }

    It 'Every _metadata block declares rollback guidance' {
        foreach ($File in $PolicyFiles) {
            $Json = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            $Json._metadata.rollback | Should -Not -BeNullOrEmpty -Because "$($File.Name) is missing rollback guidance"
        }
    }

    It 'L2 policies under Policies/L2 are not assigned to StandardUser without an assignmentNote' {
        $L2Files = $PolicyFiles | Where-Object { $_.DirectoryName -like '*Policies/L2*' -or $_.DirectoryName -like '*Policies\L2*' }
        foreach ($File in $L2Files) {
            $Json = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            if ($Json._metadata.personas -contains 'StandardUser') {
                $Json._metadata.assignmentNote | Should -Not -BeNullOrEmpty -Because "$($File.Name) applies an L2 control to StandardUser and must document why/how it was validated"
            }
        }
    }
}

Describe 'Persona definitions' {

    It 'Every persona file loads as valid PowerShell data' {
        foreach ($File in $PersonaFiles) {
            { Import-PowerShellDataFile -Path $File.FullName } | Should -Not -Throw
        }
    }

    It 'Every persona declares an UpdateRing matching the ring-intelligence repo model' {
        $ValidRings = @('Test', 'First', 'Fast', 'Broad', 'ZeroDay', 'VIP')
        foreach ($File in $PersonaFiles) {
            $Persona = Import-PowerShellDataFile -Path $File.FullName
            $Persona.UpdateRing | Should -BeIn $ValidRings -Because "$($File.Name) has an UpdateRing not in the shared ring model"
        }
    }

    It 'KioskSharedDevice does not require Windows Hello for Business' {
        $Kiosk = Import-PowerShellDataFile -Path (Join-Path $RepoRoot 'Config/Personas/KioskSharedDevice.psd1')
        $Kiosk.Controls.RequireWindowsHelloForBusiness | Should -Be $false
    }

    It 'PrivilegedAdmin requires LAPS' {
        $Admin = Import-PowerShellDataFile -Path (Join-Path $RepoRoot 'Config/Personas/PrivilegedAdmin.psd1')
        $Admin.Controls.RequireLAPS | Should -Be $true
    }
}

Describe 'Remediation script safety conventions' {

    It 'LocalAdmin remediation defaults to report-only (AutoRemediate = $false)' {
        $ScriptPath = Join-Path $RepoRoot 'Remediations/LocalAdmin/Remediate-LocalAdminGroupMembership.ps1'
        $Content = Get-Content -Path $ScriptPath -Raw
        $Content | Should -Match '\$AutoRemediate\s*=\s*\$false'
    }

    It 'Every Detect-*.ps1 script contains both an exit 0 and an exit 1 path' {
        $DetectScripts = Get-ChildItem -Path (Join-Path $RepoRoot 'Remediations') -Filter 'Detect-*.ps1' -Recurse
        foreach ($Script in $DetectScripts) {
            $Content = Get-Content -Path $Script.FullName -Raw
            $Content | Should -Match 'exit 0' -Because "$($Script.Name) should have a compliant exit path"
            $Content | Should -Match 'exit 1' -Because "$($Script.Name) should have a non-compliant exit path"
        }
    }
}

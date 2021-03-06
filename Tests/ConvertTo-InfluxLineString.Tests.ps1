if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Influx'

If (-not (Get-Module $Module)) { Import-Module "$Root\$Module" -Force }

Describe "ConvertTo-InfluxLineString PS$PSVersion" {
    
    InModuleScope Influx {

        Mock Out-InfluxEscapeString { 'Some\ \,string\=' } -Verifiable

        Mock ConvertTo-UnixTimeNanosecond { '1483274062120000000' }
       
        Context 'Simulating successful output' {
           
            $WriteInflux = ConvertTo-InfluxLineString -Measure WebServer -Tags @{Server = 'Host01'} -Metrics @{CPU = 100; Status = 'PoweredOn'} -Timestamp (Get-Date)

            It 'ConvertTo-InfluxLineString should return a string' {
                $WriteInflux | Should -BeOfType [string]
            }
            It 'Should execute all verifiable mocks' {
                Assert-VerifiableMock
            }
            It 'Should call ConvertTo-UnixTimeNanosecond exactly 1 time' {
                Assert-MockCalled ConvertTo-UnixTimeNanosecond -Exactly 1
            }
            It 'Should call Out-InfluxEscapeString exactly 7 times' {
                Assert-MockCalled Out-InfluxEscapeString -Exactly 7
            }
        }

        Context 'Simulating successful output via piped object' {
            
            $MeasureObject = [pscustomobject]@{
                PSTypeName = 'Metric'
                Measure    = 'SomeMeasure'
                Metrics    = @{One = 'One'; Two = 2}
                Tags       = @{TagOne = 'One'; TagTwo = 2}
                TimeStamp  = (Get-Date)
            }

            $WriteInflux = $MeasureObject | ConvertTo-InfluxLineString

            It 'ConvertTo-InfluxLineString should return a string' {
                $WriteInflux | Should -BeOfType [string]
            }
            It 'Should execute all verifiable mocks' {
                Assert-VerifiableMock
            }
            It 'Should call ConvertTo-UnixTimeNanosecond exactly 1 time' {
                Assert-MockCalled ConvertTo-UnixTimeNanosecond -Exactly 1
            }
            It 'Should call Out-InfluxEscapeString exactly 9 times' {
                Assert-MockCalled Out-InfluxEscapeString -Exactly 9
            }
        }

        Context 'Simulating -WhatIf and no Timestamp specified' {
            
            $WriteInflux = ConvertTo-InfluxLineString -Measure WebServer -Tags @{Server = 'Host01'} -Metrics @{CPU = 100; Status = 'PoweredOn'} -WhatIf

            It 'ConvertTo-InfluxLineString should return null' {
                $WriteInflux | Should -Be $null
            }
            It 'Should execute all verifiable mocks' {
                Assert-VerifiableMock
            }
            It 'Should call Out-InfluxEscapeString exactly 7 times' {
                Assert-MockCalled Out-InfluxEscapeString -Exactly 7
            }
            It 'Should call ConvertTo-UnixTimeNanosecond exactly 0 times' {
                Assert-MockCalled ConvertTo-UnixTimeNanosecond -Exactly 0
            }
        }

        Context 'Simulating output of metric with zero value' {
           
            $WriteInflux = ConvertTo-InfluxLineString -Measure WebServer -Tags @{Server = 'Host01'} -Metrics @{CPU = 50; Memory = 0} -Timestamp (Get-Date)

            It 'ConvertTo-InfluxLineString should return a string' {
                $WriteInflux | Should -BeOfType [string]
            }
            It 'Should execute all verifiable mocks' {
                Assert-VerifiableMock
            }
            It 'Should call ConvertTo-UnixTimeNanosecond exactly 1 time' {
                Assert-MockCalled ConvertTo-UnixTimeNanosecond -Exactly 1
            }
            It 'Should call Out-InfluxEscapeString exactly 8 times' {
                Assert-MockCalled Out-InfluxEscapeString -Exactly 8
            }
        }

        Context 'Simulating output of metric with null value' {
           
            $WriteInflux = ConvertTo-InfluxLineString -Measure WebServer -Tags @{Server = 'Host01'} -Metrics @{CPU = 50; Memory = $null} -Timestamp (Get-Date)

            It 'ConvertTo-InfluxLineString should return a string' {
                $WriteInflux | Should -BeOfType [string]
            }
            It 'Should execute all verifiable mocks' {
                Assert-VerifiableMock
            }
            It 'Should call ConvertTo-UnixTimeNanosecond exactly 1 time' {
                Assert-MockCalled ConvertTo-UnixTimeNanosecond -Exactly 1
            }
            It 'Should call Out-InfluxEscapeString exactly 7 times' {
                Assert-MockCalled Out-InfluxEscapeString -Exactly 7
            }
        }

        Context 'Simulating skip outputting null or empty metrics when -ExcludeEmptyMetric is used' {

            Mock Write-Verbose {}
            
            $MeasureObject = @(
                [PSCustomObject]@{
                    Name = 'Object1'
                    SomeVal = 1
                    OtherVal = ''
                },
                [PSCustomObject]@{
                    Name = 'Object2'
                    SomeVal = $null
                    OtherVal = 2
                }
            )

            $WriteInflux = $MeasureObject | ConvertTo-Metric -Measure Test -MetricProperty Name,SomeVal,OtherVal | ConvertTo-InfluxLineString -ExcludeEmptyMetric -Verbose
            
            It 'ConvertTo-InfluxLineString should return a string' {
                $WriteInflux | Should -BeOfType [string]
            }
            It 'Should execute all verifiable mocks' {
                Assert-VerifiableMock
            }
            It 'Should call Write-Verbose exactly 2 times' {
                Assert-MockCalled Write-Verbose -Exactly 2
            }
            It 'Should call ConvertTo-UnixTimeNanosecond exactly 0 times' {
                Assert-MockCalled ConvertTo-UnixTimeNanosecond -Exactly 0
            }
            It 'Should call Out-InfluxEscapeString exactly 10 times' {
                Assert-MockCalled Out-InfluxEscapeString -Exactly 10
            }
        }
    }
}
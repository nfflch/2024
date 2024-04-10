$data = ( Get-Content -Path "FullSchedule.tsv" | ConvertFrom-Csv -Delimiter "`t" )
ConvertTo-Json @{data = ($data)} | Set-Content -Path "FullSchedule.json"
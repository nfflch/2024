$data = (Get-Content -Path "FullSchedule.csv" | ConvertFrom-Csv -Delimiter ',')
ConvertTo-Json @{data = ($data)} | Add-Content -Path "FullSchedule.json"
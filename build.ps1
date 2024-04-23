function ConvertTo-Ics($games, $filename) {
    @"
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Zurich
X-TZINFO:Europe/Zurich[2023c]
BEGIN:STANDARD
TZOFFSETTO:+002946
TZOFFSETFROM:+003408
TZNAME:Europe/Zurich(STD)
DTSTART:18530716T000000
RDATE:18530716T000000
END:STANDARD
BEGIN:STANDARD
TZOFFSETTO:+010000
TZOFFSETFROM:+002946
TZNAME:Europe/Zurich(STD)
DTSTART:18940601T000000
RDATE:18940601T000000
END:STANDARD
BEGIN:DAYLIGHT
TZOFFSETTO:+020000
TZOFFSETFROM:+010000
TZNAME:Europe/Zurich(DST)
DTSTART:19410505T010000
RRULE:FREQ=YEARLY;BYMONTH=5;BYDAY=1MO;UNTIL=19420504T010000
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETTO:+010000
TZOFFSETFROM:+020000
TZNAME:Europe/Zurich(STD)
DTSTART:19411006T020000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=1MO;UNTIL=19421005T020000
END:STANDARD
BEGIN:STANDARD
TZOFFSETTO:+010000
TZOFFSETFROM:+020000
TZNAME:Europe/Zurich(STD)
DTSTART:19810927T030000
RRULE:FREQ=YEARLY;BYMONTH=9;BYDAY=-1SU;UNTIL=19950924T030000
END:STANDARD
BEGIN:DAYLIGHT
TZOFFSETTO:+020000
TZOFFSETFROM:+010000
TZNAME:Europe/Zurich(DST)
DTSTART:19810329T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU;UNTIL=19960331T020000
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETTO:+010000
TZOFFSETFROM:+020000
TZNAME:Europe/Zurich(STD)
DTSTART:19961027T030000
RDATE:19961027T030000
END:STANDARD
BEGIN:DAYLIGHT
TZOFFSETTO:+020000
TZOFFSETFROM:+010000
TZNAME:(DST)
DTSTART:19970330T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETTO:+010000
TZOFFSETFROM:+020000
TZNAME:(STD)
DTSTART:19971026T030000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
"@ | Set-Content -Path $filename

    $games | ForEach-Object {
        $game = $_
        if ( $null -ne $game."Date" ) {
            $date = Get-Date $game."Date" -Format "yyyyMMdd"
            $venue = $game."Venue"
            $field = $game."Field"
            $start = Get-Date $game."Start" -Format "HHmmss"
            $end = Get-Date $game."End" -Format "HHmmss"
            $homeTeam = $game."Home team"
            $awayTeam = $game."Away team"
            $hr = $game."Referee"
            $dj = $game."Lineman"
            $fj = $game."Field Judge"
            $sj = $game."Side Judge"

            @"
BEGIN:VEVENT
CLASS:PUBLIC
DTSTART;TZID=Europe/Zurich:$($date)T$($start)Z
DTEND;TZID=Europe/Zurich:$($date)T$($end)Z
LOCATION:$venue $field
SUMMARY:$homeTeam vs $awayTeam
DESCRIPTION:Head Ref: $hr\nLineman: $dj\nField Judge: $fj\nSide Judge: $sj
END:VEVENT
"@ | Add-Content -Path $filename
        }
    }

    @"
END:VCALENDAR
"@ | Add-Content -Path $filename
}

if ( !( Test-Path -PathType container "venue" ) ) {
    New-Item -ItemType Directory -Path "venue" | Out-Null
}
if ( !( Test-Path -PathType container "club" ) ) {
    New-Item -ItemType Directory -Path "club" | Out-Null
}
if ( !( Test-Path -PathType container "team" ) ) {
    New-Item -ItemType Directory -Path "team" | Out-Null
}

$clubs = ( Get-Content -Path "club.json" | ConvertFrom-Json )
Copy-Item -Path "club.json" -Destination "club/" | Out-Null

$schedule = ( Get-Content -Path "schedule.tsv" | ConvertFrom-Csv -Delimiter "`t" )

ConvertTo-Json @{data = $schedule} | Set-Content -Path "club/all.json"
Copy-Item -Path "club/all.json" -Destination "club/games.json" | Out-Null
Copy-Item -Path "club/all.json" -Destination "club/refs.json" | Out-Null
ConvertTo-Ics $schedule "club/all.ics"
Copy-Item -Path "club/all.ics" -Destination "club/games.ics" | Out-Null
Copy-Item -Path "club/all.ics" -Destination "club/refs.ics" | Out-Null
Copy-Item -Path "club/*.json" -Destination "team/" | Out-Null
Copy-Item -Path "club/*.json" -Destination "./" | Out-Null
Copy-Item -Path "club/*.ics" -Destination "team/" | Out-Null
Copy-Item -Path "club/*.ics" -Destination "./" | Out-Null

$venues = ($schedule | Select-Object @{E={$_."Date"+" "+$_."Venue"};L="Venue"} ) | Select-Object -ExpandProperty Venue -Unique | Sort-Object
$venues | ConvertTo-Json -AsArray | Set-Content -Path "venue/venue.json"

$venues | ForEach-Object {
    $date = $_.Substring(0,10)
    $venue = $_.Substring(11)
    $venueFolder = "venue/"+("$date $venue" -replace ' ', '-').ToLower()
    if ( !( Test-Path -PathType container $venueFolder ) ) {
          New-Item -ItemType Directory -Path $venueFolder | Out-Null
    }
    $venueGames = $schedule | Where-Object { $_."Date" -eq $date -and $_."Venue" -eq $venue}
    ConvertTo-Json @{data = $venueGames} | Set-Content -Path "$venueFolder/all.json"
    Copy-Item -Path "$venueFolder/all.json" -Destination "$venueFolder/games.json" | Out-Null
    Copy-Item -Path "$venueFolder/all.json" -Destination "$venueFolder/refs.json" | Out-Null
    ConvertTo-Ics $venueGames "$venueFolder/all.ics"
    Copy-Item -Path "$venueFolder/all.ics" -Destination "$venueFolder/games.ics" | Out-Null
    Copy-Item -Path "$venueFolder/all.ics" -Destination "$venueFolder/refs.ics" | Out-Null

    $teams = ($venueGames | Select-Object @{E={$_."Home team"};L="Team"} ) + ($venueGames | Select-Object @{E={$_."Away team"};L="Team"} ) | Select-Object -ExpandProperty Team -Unique | Where-Object { $_ -match '^\w{1,3}\s' } | Sort-Object
    $teams | ConvertTo-Json -AsArray | Set-Content -Path "$venueFolder/team.json"

    $venueClubs = @()
    $clubs | ForEach-Object {
        $club = $_
        $clubGames = $venueGames | Where-Object { $_."Home team" -like "* $club*" -or $_."Away team" -like "* $club*" }

        if ($clubGames.Count -eq 0) {
            return
        }

        $venueClubs += $club
        $clubFolder = "$venueFolder/club/"+($club -replace ' ', '-').ToLower()
        if ( !( Test-Path -PathType container $clubFolder ) ) {
              New-Item -ItemType Directory -Path $clubFolder | Out-Null
        }

        ConvertTo-Json @{data = $clubGames} | Set-Content -Path "$clubFolder/games.json"
        ConvertTo-Ics $clubGames "$clubFolder/games.ics"
    
        $clubRefs = $venueGames | Where-Object { $_."Referee" -like "* $club*" -or $_."Lineman" -like "* $club*" -or $_."Field Judge" -like "* $club*" -or $_."Side Judge" -like "* $club*" }
        ConvertTo-Json @{data = $clubRefs} | Set-Content -Path "$clubFolder/refs.json"
        ConvertTo-Ics $clubRefs "$clubFolder/refs.ics"
    
        $clubGamesRefs = $venueGames | Where-Object { $_."Home team" -like "* $club*" -or $_."Away team" -like "* $club*" -or $_."Referee" -like "* $club*" -or $_."Lineman" -like "* $club*" -or $_."Field Judge" -like "* $club*" -or $_."Side Judge" -like "* $club*" }
        ConvertTo-Json @{data = $clubGamesRefs} | Set-Content -Path "$clubFolder/all.json"
        ConvertTo-Ics $clubGamesRefs "$clubFolder/all.ics"

        $clubTeams = @()
        $teams | Where-Object { $_ -like "* $club*" } | ForEach-Object {
            $team = $_
            $clubTeams += $team
            $teamFolder = ($team -replace ' ', '-').ToLower()
    
            $clubTeamFolder = "$clubFolder/team/$teamFolder/"
            if ( !( Test-Path -PathType container $clubTeamFolder ) ) {
                  New-Item -ItemType Directory -Path $clubTeamFolder | Out-Null
            }
    
            $teamGames = $venueGames | Where-Object { $_."Home team" -eq $team -or $_."Away team" -eq $team }
            ConvertTo-Json @{data = $teamGames} | Set-Content -Path "$clubTeamFolder/games.json"
            ConvertTo-Ics $teamGames "$clubTeamFolder/games.ics"
    
            $teamRefs = $venueGames | Where-Object { $_."Referee" -eq $team -or $_."Lineman" -eq $team -or $_."Field Judge" -eq $team -or $_."Side Judge" -eq $team }
            ConvertTo-Json @{data = $teamRefs} | Set-Content -Path "$clubTeamFolder/refs.json"
            ConvertTo-Ics $teamRefs "$clubTeamFolder/refs.ics"
    
            $teamGamesRefs = $venueGames | Where-Object { $_."Home team" -eq $team -or $_."Away team" -eq $team -or $_."Referee" -eq $team -or $_."Lineman" -eq $team -or $_."Field Judge" -eq $team -or $_."Side Judge" -eq $team }
            ConvertTo-Json @{data = $teamGamesRefs} | Set-Content -Path "$clubTeamFolder/all.json"
            ConvertTo-Ics $teamGamesRefs "$clubTeamFolder/all.ics"
            Copy-Item -Path $clubTeamFolder -Destination "$venueFolder/team/" -Recurse | Out-Null
    
        }
        $clubTeams | ConvertTo-Json -AsArray | Set-Content -Path "$clubFolder/team.json"
    }
    $venueClubs | ConvertTo-Json -AsArray | Set-Content -Path "$venueFolder/club.json"
}

$teams = ($schedule | Select-Object @{E={$_."Home team"};L="Team"} ) + ($schedule | Select-Object @{E={$_."Away team"};L="Team"} ) | Select-Object -ExpandProperty Team -Unique | Where-Object { $_ -match '^\w{1,3}\s' } | Sort-Object

$teams | ConvertTo-Json -AsArray | Set-Content -Path "team/team.json"
Copy-Item -Path "team/team.json" -Destination "club/" | Out-Null
Copy-Item -Path "team/team.json" -Destination "./" | Out-Null

$clubs | ForEach-Object {
    $club = $_
    $clubFolder = "club/"+($club -replace ' ', '-').ToLower()
    if ( !( Test-Path -PathType container $clubFolder ) ) {
          New-Item -ItemType Directory -Path $clubFolder | Out-Null
    }
    $clubGames = $schedule | Where-Object { $_."Home team" -like "* $club*" -or $_."Away team" -like "* $club*" }
    ConvertTo-Json @{data = $clubGames} | Set-Content -Path "$clubFolder/games.json"
    ConvertTo-Ics $clubGames "$clubFolder/games.ics"

    $clubRefs = $schedule | Where-Object { $_."Referee" -like "* $club*" -or $_."Lineman" -like "* $club*" -or $_."Field Judge" -like "* $club*" -or $_."Side Judge" -like "* $club*" }
    ConvertTo-Json @{data = $clubRefs} | Set-Content -Path "$clubFolder/refs.json"
    ConvertTo-Ics $clubRefs "$clubFolder/refs.ics"

    $clubGamesRefs = $schedule | Where-Object { $_."Home team" -like "* $club*" -or $_."Away team" -like "* $club*" -or $_."Referee" -like "* $club*" -or $_."Lineman" -like "* $club*" -or $_."Field Judge" -like "* $club*" -or $_."Side Judge" -like "* $club*" }
    ConvertTo-Json @{data = $clubGamesRefs} | Set-Content -Path "$clubFolder/all.json"
    ConvertTo-Ics $clubGamesRefs "$clubFolder/all.ics"

    $clubTeams = @()
    $teams | Where-Object { $_ -like "* $club*" } | ForEach-Object {
        $team = $_
        $clubTeams += $team
        $teamFolder = ($team -replace ' ', '-').ToLower()

        $clubTeamFolder = "$clubFolder/team/$teamFolder/"
        if ( !( Test-Path -PathType container $clubTeamFolder ) ) {
              New-Item -ItemType Directory -Path $clubTeamFolder | Out-Null
        }

        $teamGames = $schedule | Where-Object { $_."Home team" -eq $team -or $_."Away team" -eq $team }
        ConvertTo-Json @{data = $teamGames} | Set-Content -Path "$clubTeamFolder/games.json"
        ConvertTo-Ics $teamGames "$clubTeamFolder/games.ics"

        $teamRefs = $schedule | Where-Object { $_."Referee" -eq $team -or $_."Lineman" -eq $team -or $_."Field Judge" -eq $team -or $_."Side Judge" -eq $team }
        ConvertTo-Json @{data = $teamRefs} | Set-Content -Path "$clubTeamFolder/refs.json"
        ConvertTo-Ics $teamRefs "$clubTeamFolder/refs.ics"

        $teamGamesRefs = $schedule | Where-Object { $_."Home team" -eq $team -or $_."Away team" -eq $team -or $_."Referee" -eq $team -or $_."Lineman" -eq $team -or $_."Field Judge" -eq $team -or $_."Side Judge" -eq $team }
        ConvertTo-Json @{data = $teamGamesRefs} | Set-Content -Path "$clubTeamFolder/all.json"
        ConvertTo-Ics $teamGamesRefs "$clubTeamFolder/all.ics"
        Copy-Item -Path $clubTeamFolder -Destination "team/" -Recurse | Out-Null

    }
    $clubTeams | ConvertTo-Json -AsArray | Set-Content -Path "$clubFolder/team.json"
}
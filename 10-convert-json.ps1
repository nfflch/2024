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

$data = ( Get-Content -Path "schedule.tsv" | ConvertFrom-Csv -Delimiter "`t" )

ConvertTo-Json @{data = $data} | Set-Content -Path "schedule.json"
ConvertTo-Ics $teamGames "schedule.ics"

$teams = ($data | Select-Object @{E={$_."Home team"};L="Team"} ) + ($data | Select-Object @{E={$_."Away team"};L="Team"} ) | Select-Object -ExpandProperty Team -Unique | Where-Object { $_ -match '^\w{1,3}\s' } | Sort-Object

$teams | ConvertTo-Json | Set-Content -Path "teams.json"

$teams | ForEach-Object {
    $team = $_
    $filename = ($_ -replace ' ', '-').ToLower()

    $teamGames = $data | Where-Object { $_."Home team" -eq $team -or $_."Away team" -eq $team }
    ConvertTo-Json @{data = $teamGames} | Set-Content -Path "team/$filename-games.json"
    ConvertTo-Ics $teamGames "team/$filename-games.ics"

    $teamRefs = $data | Where-Object { $_."Referee" -eq $team -or $_."Lineman" -eq $team -or $_."Field Judge" -eq $team -or $_."Side Judge" -eq $team }
    ConvertTo-Json @{data = $teamRefs} | Set-Content -Path "team/$filename-refs.json"
    ConvertTo-Ics $teamRefs "team/$filename-refs.ics"

    $teamGamesRefs = $data | Where-Object { $_."Home team" -eq $team -or $_."Away team" -eq $team -or $_."Referee" -eq $team -or $_."Lineman" -eq $team -or $_."Field Judge" -eq $team -or $_."Side Judge" -eq $team }
    ConvertTo-Json @{data = $teamGamesRefs} | Set-Content -Path "team/$filename-all.json"
    ConvertTo-Ics $teamGamesRefs "team/$filename-all.ics"
}

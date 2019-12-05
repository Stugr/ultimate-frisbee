$people = Import-Csv "$PSScriptRoot\Hat Rego 2nd december.csv"

# set team size
$teamSize = 12

# how many people in the csv
"There are $($people.count) in the csv"

# remove people who haven't completed signup
$people = $people | ? { $_.status -eq "accepted" }

# how many have completed signup
"There are $($people.count) who have completed signup"

# add knowledge to make it shorter
$people | Add-Member "Knowledge" -membertype noteproperty -Value ""
$people | % { $_.knowledge = $_."knowledge_+_experience" }

# add captains
$people | Add-Member "Captain" -membertype noteproperty -Value ""

$captains = @(
    "Ryan Alexander",
    "James Branson",
    "Wally Crocker",
    "Richard Moore",
    "Lars Erik Gustav Berggren",
    "Rousheen (Rush) Paisley",
    "Julian Reynolds",
    "Rapha�l Buelens",
    "Martin O'Brien",
    "Samara Nothard"
)

foreach ($c in $captains) {
    ($people | ? { $_.first_name -eq $c.Substring(0, $c.LastIndexOf(" ")) -and $_.last_name -eq $c.Substring($c.LastIndexOf(" ") + 1) }).captain = "yes"
}

# fix bad gender data
($people | ? { $_.first_name -eq "Mimi" -and $_.last_name -eq "Suwan" }).gender = "female"


# weighting will use whatever smart single and double quotes that are in the source csv to allow for copying and pasting into the structure below
# leading and trailing spaces are trimmed when comparing
# weighting is ordered, so that threshold checks against total score can be done near the end can be done in a single loop
$weighting = [ordered]@{
    'fitness' = @{
        'multiplier' = 1;
        'translation' = @{
            '1 - Melbourne hat is going to kick my ass' = 1;
            "2 - I�m average normal person fit" = 2;
            "3 - I�m average frisbee player fit" = 3;
            "4 - I�m very fit" = 4;
            "5 - I�m a total gun and will run all damn day as if powered by other people�s suffering" = 5;
        };
    };
    'throwing_ability' = @{
        'multiplier' = 1;
        'translation' = @{
            'Beginner' = 1;
            'Confident with basic throws, lacking distance or control' = 2;
            'Confident with most throws, medium range' = 3;
            'Confident handler' = 4;
            'Can put the disc anywhere' = 5;
        };
    };
    'level_of_play' = @{
        'multiplier' = 1.2;
        'translation' = @{
            'Social' = 1;
            'Competitive League' = 2;
            'Regionals/Div 2 Nats/Other Tournaments' = 3;
            'Div 1 Nats/International Tournaments' = 4;
            'Worlds' = 5;
        };
    };
    'Knowledge' = @{
        'multiplier' = .5;
        'translation' = @{
            'Beginner' = 1;
            "I�ve played some leagues etc but I still get confused by the pick rule" = 2;
            "Played plenty, can teach the rules but I still get confused by the pick rule" = 3;
            "Know the game inside and out but I still get confused by the pick rule" = 4;
            "I�m Rueben Berg and I know the pick rule." = 5;
        };
    };
    'Experience' = @{
        'multiplier' = 1.2;
        'translation' = @{
            'Beginner' = 1;
            'Intermediate' = 3;
            'Experienced' = 4;
            'Guru' = 5;
        };
    };
    # if total score is less than 12, then short people will get a lower score - height is useful when you're a beginner
    'Height' = @{
        'threshold' = '-lt 12';
        'multiplier' = 1;
        'default' = 0;
        'translation' = @{
            '<150cm' = -2;
            '150-160cm' = -1;
            '160-170cm' = -.5;
            '170-180cm' = -.2;
            '180-190cm' = 0;
            '>190cm' = 0;
            '180-190cm,>190cm' = 0; # the form wrongly allowed multiselect
        };
    };
}

# sort order - sort by gender ascending (female, then male), then by score descending
$sortOrder = @(
    @{
        expression = 'gender';
        descending = $false;
    },
    @{
        expression = 'score_total';
        descending = $true;
    }
)

# count of groupings with scores (doesn't use multiplier)
foreach ($w in $weighting.GetEnumerator()) {
    $people.($w.Name) | group | select @{N='Weighting';E={$w.Name}}, count, name, @{N='Score';E={$weighting.($w.name).translation.($_.name.trim())}}
}

# loop through people and turn their values into scores
foreach ($p in $people) {
    # add property to record total score
    $p | Add-Member "score_total" -membertype noteproperty -Value 0

    # loop through weightings
    foreach ($w in $weighting.GetEnumerator()) {
        # get the score name
        $scoreName = "score_$($w.Name)"

        # translate the text into it's value (trimmed to removed erroneous spaces)
        $scoreBeforeMultiplier = $weighting.($w.name).translation.($p.($w.name).trim())

        # if we have a threshold defined to check total score against
        if ($weighting.($w.name).threshold) {
            # if total score doesn't match threshold then set it to the default
            if (-not (Invoke-Expression "$($p.score_total) $($weighting.($w.name).threshold)")) {
                $scoreBeforeMultiplier = $weighting.($w.name).default
            }
        }

        # add property to record the score - now it is multiplied
        $p | Add-Member $scoreName -membertype noteproperty -Value ($scoreBeforeMultiplier * $weighting.($w.name).multiplier)

        # add to total score
        $p.score_total += $p.$scoreName
    }
}

# get the highest and lowest possible scores
$peopleScoreMax = 0
$peopleScoreMin = 0
foreach ($w in $weighting.GetEnumerator()) {
    $peopleScoreMax += ($weighting.($w.name).translation.GetEnumerator() | sort value -Descending | select -First 1).value * $weighting.($w.name).multiplier
    $peopleScoreMin += ($weighting.($w.name).translation.GetEnumerator() | sort value | select -First 1).value * $weighting.($w.name).multiplier
}

# sort based on our sort order
$people = ($people | sort $sortOrder)

# build select fields
$select = @('first_name', 'last_name', 'gender', 'score_total')
foreach ($w in $weighting.GetEnumerator()) {
    $select += "score_$($w.Name)"
}

# select everyone and their scores
$people | select $select | ft -auto

# number of teams based on size
$teamNumber = $([math]::Floor($people.Count / $teamSize))

# number of females
$femaleNumber = ($people | ? { $_.gender -eq 'female'} ).Count

# score total and avg
$peopleScoreTotal = ($people.score_total | measure -Sum).sum
$peopleScoreAverage = [math]::Round($peopleScoreTotal / $people.Count, 2)

# print some stats
"There are $($people.Count) people - $femaleNumber females and $($people.count - $femaleNumber) males"
"With $($people.Count) people and team sizes of $teamSize there will be $teamNumber teams and $($people.Count % $teamSize) person left over"
"Teams will have $([math]::Round($femaleNumber / $teamNumber, 2)) females each"
"Total score equals $peopleScoreTotal with the average score being $peopleScoreAverage"
"Each team will be worth an average of $($peopleScoreAverage * $teamSize) points (min score for a person is $peopleScoreMin and max score is $peopleScoreMax)"

# add property to store which team each person is on
$people | Add-Member "Team" -membertype noteproperty -Value ""

# re-order people to make even numbers of females, then males based on teams, then put the spare females and males on the end
$reorderedPeople = @()

# even numbers of females
$reorderedPeople = $people | ? { $_.gender -eq "female" } | select -first ($femaleNumber - ($femaleNumber % $teamNumber))
# even numbers of males
$reorderedPeople += $people | ? { $_.gender -ne "female" } | select -first (($people.count - $femaleNumber) - (($people.count - $femaleNumber) % $teamNumber))

# leftover females
if ($femaleNumber % $teamNumber) {
    $reorderedPeople += $people | ? { $_.gender -eq "female" } | select -last ($femaleNumber % $teamNumber)
}

#leftover males
if (($people.count - $femaleNumber) % $teamNumber) {
    $reorderedPeople += $people | ? { $_.gender -eq "male" } | select -last (($people.count - $femaleNumber) % $teamNumber)
}

$people = $reorderedPeople


$i = 0
# loop through people
foreach ($person in $people) {
    # put one person into each team to start with
    if ($i -lt $teamNumber) {
        $i++
        $teamAssignment = $i
    }
    # once all teams have a person in them
    else {
        # get smallest team with lowest score
        $possibleTeams = $people | ? { $_.team -ne "" } | group team | select @{N="TeamNumber";E={$_.name}}, Count, @{N="TeamScore";E={($_.group | measure -sum score_total).sum}}, @{N="HasCaptain";E={ if ($_.group | ? { $_.captain -eq "yes" }) { $true } else { $false }}} | sort count, teamscore
        
        # if person is a captain, put them on a team that hasn't got one yet
        if ($person.captain -eq "yes") {
            $teamAssignment = ($possibleTeams | ? { -not $_.hascaptain } | select -first 1).teamnumber
        } else {
            $teamAssignment = ($possibleTeams | select -first 1).teamnumber
        }
    }

    # assign person to team
    $person.Team = [int]$teamAssignment
}


# get team totals
$people | group team | select @{N="TeamNumber";E={$_.name}}, Count, @{N="TeamScore";E={($_.group | measure -sum score_total).sum}}, @{N="Females";E={(($_.group | ? { $_.gender -eq 'female'}).count)}}, 
@{N="TeamScoreBest6";E={($_.group | sort score_total -Descending | select -first 6 | measure -sum score_total).sum}},
@{N="TeamScoreBest6With3Women";E={($_.group | ? { $_.gender -eq 'female'} | sort score_total -Descending | select -first 3 | measure -sum score_total).sum + ($_.group | ? { $_.gender -ne 'female'} | sort score_total -Descending | select -first 3 | measure -sum score_total).sum}},
@{N="TeamScoreBest6With2Women";E={($_.group | ? { $_.gender -eq 'female'} | sort score_total -Descending | select -first 2 | measure -sum score_total).sum + ($_.group | ? { $_.gender -ne 'female'} | sort score_total -Descending | select -first 4 | measure -sum score_total).sum}} | ft -auto

# export to csv
$dateTime = Get-Date -format "yyyyMMdd HHmmss"
$people | select first_name, last_name, gender, score_total, team, captain, fitness, score_fitness, throwing_ability, score_throwing_ability, level_of_play, score_level_of_play, knowledge, score_knowledge, experience, score_experience, height, score_height, shirt_size, "party rsvp", "friday rsvp", "Dietary_Requirements_Context:", Other_dietary_requirements, "club affiliation", Did_you_play, Dietary, offer_billet, need_billet, "Product Melbourne Hat 2019 Individual Registration", "Product Melbourne Hat Disc" | Export-Csv -NoTypeInformation "$PSScriptRoot\$dateTime-teams.csv" -Encoding UTF8

$lastTeam = 0
# create empty object to hold the team row heading
$teamRowHeading = New-Object PsObject
$people | Get-Member -MemberType Properties | % { $teamRowHeading | Add-Member -MemberType $_.MemberType -Name $_.Name -Value "" } 
#$people | sort team, last_name, gender| % { if ($_.team -ne $lastTeam) { $teamRowHeading.first_name = "Team $($_.team)"; $teamRowHeading }; $_; $lastTeam = $_.team; } | select team, first_name, last_name, gender
#$people | sort team, captain, last_name, gender| % { if ($_.team -ne $lastTeam) { $teamRowHeading }; $_; $lastTeam = $_.team; } | select team, first_name, last_name, gender, captain | Export-Csv -NoTypeInformation "$PSScriptRoot\$dateTime-teams-forPrintingOrderedByTeam.csv" -Encoding UTF8
$people | sort last_name, gender, team | select first_name, last_name, gender, team, shirt_size | Export-Csv -NoTypeInformation "$PSScriptRoot\$dateTime-teams-forPrintingOrderedBySurname.csv" -Encoding UTF8

$sortOrderForCsv = @(
    @{
        expression = 'team';
        descending = $false;
    },
    @{
        expression = 'captain';
        descending = $true;
    }
    @{
        expression = 'last_name';
        descending = $false;
    }
    @{
        expression = 'gender';
        descending = $false;
    }
)

$people | sort $sortOrderForCsv | % { if ($_.team -ne $lastTeam) { $teamRowHeading }; $_; $lastTeam = $_.team; } | select team, first_name, last_name, gender, captain | Export-Csv -NoTypeInformation "$PSScriptRoot\$dateTime-teams-forPrintingOrderedByTeam.csv" -Encoding UTF8

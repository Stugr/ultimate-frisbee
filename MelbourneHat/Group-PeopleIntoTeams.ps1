$people = Import-Csv $PSScriptRoot\Melbourne-Hat-2019_2019-11-02-12_01.csv

# how many people in the csv
"There are $($people.count) in the csv"

# remove people who haven't completed signup
$people = $people | ? { $_.fitness }

# how many have completed signup
"There are $($people.count) who have completed signup"

# remove the text from fitness just keeping the digit at the start
#$people | % { $_.fitness = ($_.fitness) -replace '^(\d+).*', '$1' }

# add knowledge to make it shorter
$people | Add-Member "Knowledge" -membertype noteproperty -Value ""
$people | % { $_.knowledge = $_."knowledge_+_experience" }
# remove old knowledge property
$people = $people | select -Property * -ExcludeProperty "knowledge_+_experience"

$weighting = @{
    'fitness' = @{
        'multiplier' = 1;
        'translation' = @{
            '1 - Melbourne hat is going to kick my ass' = 1;
            "2 - I知 average normal person fit " = 2; # ugh trailing space
            "3 - I知 average frisbee player fit" = 3;
            "4 - I知 very fit" = 4;
            "5 - I知 a total gun and will run all damn day as if powered by other people痴 suffering" = 5;
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
            "I致e played some leagues etc but I still get confused by the pick rule" = 2;
            "Played plenty, can teach the rules but I still get confused by the pick rule" = 3;
            "Know the game inside and out but I still get confused by the pick rule" = 4;
            "I知 Rueben Berg and I know the pick rule." = 5;
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
}

#$filter = @(
#    "gender -eq 'female'",
#    "gender -eq 'male'"
#)

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

# count of groupings with scores (not using multiplier yet)
foreach ($w in $weighting.GetEnumerator()) {
    $people.($w.Name) | group | select @{N='Weighting';E={$w.Name}}, count, name, @{N='Score';E={$weighting.($w.name).translation.($_.name)}}
}

# loop through people and turn their values into scores (not using multiplier yet)
foreach ($p in $people) {
    $p | Add-Member "score_total" -membertype noteproperty -Value 0
    foreach ($w in $weighting.GetEnumerator()) {
        $scoreName = "score_$($w.Name)"
        $scoreBeforeMultiplier = $weighting.($w.name).translation.($p.($w.name))
        $p | Add-Member $scoreName -membertype noteproperty -Value ($scoreBeforeMultiplier * $weighting.($w.name).multiplier)
        $p.score_total += $p.$scoreName
    }
}

# min max scores
$peopleScoreMax = 0
$peopleScoreMin = 0
foreach ($w in $weighting.GetEnumerator()) {
    $peopleScoreMax += ($weighting.($w.name).translation.GetEnumerator() | sort value -Descending | select -First 1).value * $weighting.($w.name).multiplier
    $peopleScoreMin += ($weighting.($w.name).translation.GetEnumerator() | sort value | select -First 1).value * $weighting.($w.name).multiplier
}

# build select fields
$select = @('first_name', 'last_name', 'gender', 'score_total')
foreach ($w in $weighting.GetEnumerator()) {
    $select += "score_$($w.Name)"
}

$people = ($people | sort $sortOrder)

# select everyone and their scores
$people | select $select | ft -auto
#$people | select $select | sort score_total -desc | ft -auto

# team size
$teamSize = 12
$teamNumber = $([math]::Floor($people.Count / $teamSize))
"With $($people.Count) people and team sizes of $teamSize there will be $teamNumber teams and $($people.Count % $teamSize) person left over"

# score total and avg
$peopleScoreTotal = ($people.score_total | measure -Sum).sum
$peopleScoreAverage = [math]::Round($peopleScoreTotal / $people.Count, 2)
"Total score equals $peopleScoreTotal with the average score being $peopleScoreAverage"

# team avg
"Each team will be worth an average of $($peopleScoreAverage * $teamSize) points (min score for a person is $peopleScoreMin and max score is $peopleScoreMax)"

# add team property
$people | Add-Member "Team" -membertype noteproperty -Value ""

$i = 1
$reverseDirection = $true
$teamAssignment = 0
0..($people.count-1) | % {
    $i = $_
    if ($i % $teamNumber -eq 0) {
        # flip direction
        $reverseDirection = -not $reverseDirection
        if ($i % ($teamNumber * 2) -eq 0) {
            $teamAssignment = 0
        } else {
            $teamAssignment = $teamNumber + 1
        }
    }
    # assign team
    if ($reverseDirection) {
        $teamAssignment -= 1
    } else {
        $teamAssignment += 1
    }

    $people[$i].Team = $teamAssignment
}

# get team totals
1..$teamNumber | % {
    $i = $_
    $people | ? { $_.team -eq $i } | measure -Sum score_total | select @{N="Team";E={$i}}, sum
}

# export to csv
$dateTime = Get-Date -format "ddMMyyyy HHmmss"
#$people | Export-Csv -NoTypeInformation "$PSScriptRoot\$dateTime-teams.csv" -Encoding UTF8

$people | select first_name, last_name, gender, height, score_total, team, fitness, score_fitness, throwing_ability, score_throwing_ability, level_of_play, score_level_of_play, knowledge, score_knowledge, experience, score_experience | Export-Csv -NoTypeInformation "$PSScriptRoot\$dateTime-teams.csv" -Encoding UTF8

# add players to each team
# reorder teams based on score
# add players and keep reordering
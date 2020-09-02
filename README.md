# UltimateFrisbee

- Use answers given by attendees to score each player, and then make "even" teams with similar total scores.
- Captains are pre-chosen (players had to nominate)
- Team size is set at the top (12)

Scoring
-------
- Objective answers `level_of_play` and `experience` are multiplied by 1.2. `experience` only had 4 possible answers so 2 was left out to represent the greater difference between beginner and intermediate
- Subjective answers `fitness` and `throwing_ability` are left as is (1x multiplier) while `knowledge` is less important so is halved (.5x)
- If a players total score is less than 12, then `height` is also taken into consideration as height is useful when you're a beginner

Sorting
-------
1. People are sorted by score descending
2. Based on team size, the number of teams is set (`total people / chosen team size`)
3. Re-order people to make even numbers of females, then males (based on number of teams), then put the spare females and males on the end
  eg. if the number of teams was 3, then a people list that looked like this originally `FFFFFFFFFFFMMMMMMMMMMMMM` would become `FFFFFFFFFMMMMMMMMMMMMFMM`
4. Using this new ordered list of people, loop through it one by one assigning a person to each team until all teams have a single person on them
5. Once all teams have one person, loop through the remaining people, each time doing:
  5. Sort teams size asc (smallest team first), then current total score asc (lowest score)
  5. If the next person is a captain, add them to the next smallest/worst team that hasn't got a captain yet
  5. If not then add them to the team at the top of the list (smallest/worst)

File output
-----------

Print these 2 files so that people can find what team they are on by looking up their name, but also easily see who else is on their team

`teams-forPrintingOrderedBySurname.csv`
`teams-forPrintingOrderedByTeam.csv`

A copy of the teams with scores included in case tournament directors need to do any last minute swapping (makes it easier to find someone of a similar score to swap with)

`teams-WithScoresForPrintingOrderedByTeam.csv`

Full and summary info

`teams.csv` - copy of original csv with all the scores and teams added (contains original personal info so shouldn't be shared)
`teamsSummary.csv`
```
TeamNumber Count TeamScore Females TeamScoreBest6 TeamScoreBest6With3Women TeamScoreBest6With2Women
---------- ----- --------- ------- -------------- ------------------------ ------------------------
1             13     167.6       5            100                     96.5                      100
2             13     171.1       5           99.5                     95.9                     99.5
3             13     167.6       5           96.5                     93.6                     96.5
4             13     166.6       6           96.6                     93.9                     96.6
5             13       172       5           94.6                     93.1                     94.6
6             13     167.7       5           95.8                     93.1                     95.8
7             13       172       5           95.1                     94.1                     95.1
8             13     169.7       5           95.3                     93.1                     95.3
9             13     170.1       5           95.1                     93.9                     95.1
10            13     169.6       5           94.6                     93.6                     94.6
```

Sample on-screen output
-----------------------
```
There are 140 in the csv
There are 130 who have completed signup

There are 130 people - 51 females and 79 males
With 130 people and team sizes of 12 there will be 10 teams and 10 people/person left over
Teams will have 5.1 females each
Total score equals 1694 with the average score being 13.03
Each team will be worth an average of 156.36 points (min score for a person is 2.9 and max score is 24.5)

Weighting        Count Name                                                                                    Score
---------        ----- ----                                                                                    -----
fitness              8 1 - Melbourne hat is going to kick my ass                                                   1
fitness             38 2 - I’m average normal person fit                                                           2
fitness             63 3 - I’m average frisbee player fit                                                          3
fitness             18 4 - I’m very fit                                                                            4
fitness              3 5 - I’m a total gun and will run all damn day as if powered by other people’s suffering     5
throwing_ability     9 Beginner                                                                                    1
throwing_ability    25 Confident with basic throws, lacking distance or control                                    2
throwing_ability    69 Confident with most throws, medium range                                                    3
throwing_ability    24 Confident handler                                                                           4
throwing_ability     3 Can put the disc anywhere                                                                   5
level_of_play       43 Social                                                                                      1
level_of_play       29 Competitive League                                                                          2
level_of_play       50 Regionals/Div 2 Nats/Other Tournaments                                                      3
level_of_play        7 Div 1 Nats/International Tournaments                                                        4
level_of_play        1 Worlds                                                                                      5
Knowledge           14 Beginner                                                                                    1
Knowledge           33 I’ve played some leagues etc but I still get confused by the pick rule                      2
Knowledge           55 Played plenty, can teach the rules but I still get confused by the pick rule                3
Knowledge           18 Know the game inside and out but I still get confused by the pick rule                      4
Knowledge           10 I’m Rueben Berg and I know the pick rule.                                                   5
Experience          21 Beginner                                                                                    1
Experience          82 Intermediate                                                                                3
Experience          26 Experienced                                                                                 4
Experience           1 Guru                                                                                        5
Height               1 <150cm                                                                                     -2
Height              13 150-160cm                                                                                  -1
Height              36 160-170cm                                                                                -0.5
Height              48 170-180cm                                                                                -0.2
Height              28 180-190cm                                                                                   0
Height               3 >190cm                                                                                      0
Height               1 180-190cm,>190cm                                                                            0
```

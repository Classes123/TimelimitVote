# Timelimit Vote

#### About:
* Voting consists of 2 to 6 time options.
* The result is calculated as the closest to the average value.

#### Cvars:
```
// Path: /cfg/sourcemod/plugin.timelimit_vote.cfg

// Delay before the start of the first round.
// -
// Default: "3.0"
// Minimum: "0.000000"
sm_timelimit_vote_delay "3.0"

// Duration of the vote. (0 - until everyone votes)
// -
// Default: "20"
// Minimum: "0.000000"
sm_timelimit_vote_duration "20"

// Hide information about votes.
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
sm_timelimit_vote_hidevotes "0"

// Items (minutes) that can be chosen in the vote. (Each item must be greater than 0.0 and the total number must be no less than 2 and no more than 6)
// -
// Default: "10 20 30 40 50 60"
sm_timelimit_vote_items "10 20 30 40 50 60"

// Minimum number of players required to start the vote.
// -
// Default: "2"
// Minimum: "1.000000"
// Maximum: "MaxClients"
sm_timelimit_vote_minplayers "2"
```

#### Requirements:
* (For compilation only) `colors.inc` by \_wS\_ (contained in the repository) (Info: https://world-source.ru/forum/118-5009-1)

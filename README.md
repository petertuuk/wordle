# Wordle Tools
Tools for solving and analyzing [Wordle](https://www.powerlanguage.co.uk/wordle/).

## Introduction

### Install
To get started, load the code:
```
julia> include("wordle.jl")
```

### Modes
There are three basic functions: simulate, test, and assist (described below). Each of these has three modes:
1. `"all"`: uses all words in the wordlist to choose a guess. This has the best solution performance but is slower and may use obscure words as guesses.
2. `"answers"`: uses words in the answer list to choose a guess.
3. `"remaining"`: uses remaining valid answers (given the revealed constraints) to choose a guess. This has worse performance but is faster.

## Functions
### Simulate
Simulate games using `sim()`. All arguments are optional.
```
julia> sim(solution="crumb",inputGuesses=["oater"],mode="all",verbose=true)
Solution is CRUMB

/// Guess 1 ///
Guessing OATER
Result is: [0 0 0 0 1]
66 answers remain

/// Guess 2 ///
Guessing SCULK (35 bins)
Result is: [0 1 2 0 0]
3 answers remain: CHURN CRUMB CRUMP

/// Guess 3 ///
Guessing CRUMB (3 bins)
You win!
```

### Test
Test the solver using `testMode()`. This uses multi-threading to reduce runtime.
```
julia> testMode("answers")
Testing mode = answers
Progress: 100%|███████████████████████████████████████| Time: 0:01:32
Solved 2315 of 2315 cases in an average of 3.54 guesses
1 guess: 0
2 guess: 74
3 guess: 1010
4 guess: 1127
5 guess: 104
6 guess: 0
X guess: 0
```

### Assist
Help yourself play a Wordle game using `assist()`.
```
julia> assist(mode="answers")
/// Guess 1 ///
Suggested guess is: OATER
Input your guess:
oater
Input the result (gray=0, yellow=1, green=2):
01002
9 answers remain: AUGUR BRIAR CHAIR CIGAR FLAIR FRIAR LUNAR SUGAR VICAR

/// Guess 2 ///
Suggested guess is: FICUS
Input your guess:
rival
Input the result (gray=0, yellow=1, green=2):
10020
1 answer remains: SUGAR

/// Guess 3 ///
Suggested guess is: SUGAR
Input your guess:
sugar
Input the result (gray=0, yellow=1, green=2):
22222
You win!
```

## Dependencies
This requires `Plots` and `ProgressMeter`
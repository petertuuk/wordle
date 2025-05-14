using DataStructures: DefaultDict

bestFirstGuess = "trace"

include("list-wordle.jl"); # words, answers
answers = answers[sortperm(rand(length(answers)))];
words = union(words,answers)

function filterWords(grays,yellows,greens,pastGuesses::Vector{String} = [])
    isRemain = fill(false,size(answers))
    for ii = 1:length(answers)
        isOk = true
        aa = answers[ii]
        for grayLetter in grays
            #todo: in cases with >n instances of a letter in a guess, and n instances of that letter in the solution, the result for the n+1 and later instances of that letter will be gray even though that letter is in the solution. Current logic would eliminate the correct solution. Need some other kind of constraint to indicate that there are fewer than n+1 instances of the letter in the solution
            if grayLetter in aa
                isOk = false
                break
            end
        end

        if isOk
            for gkey in keys(greens)
                locs = greens[gkey]
                for l in locs
                    if aa[l] != gkey
                        isOk = false
                        break
                    end
                end
            end
        end

        if isOk
            for ykey in keys(yellows)
                ylocs = yellows[ykey]
                for l in ylocs
                    if aa[l] == ykey
                        isOk = false
                        break
                    end
                end
                otherlocs = setdiff(1:5,ylocs)
                if !(ykey in aa[otherlocs])
                    isOk = false
                end
            end
        end
        isRemain[ii] = isOk
    end
    return sort(setdiff(answers[isRemain],pastGuesses))
end

function getConstraints(guess,result)
    grays = Set{Char}()
    yellows = Dict{Char,Set{Int}}()
    greens = Dict{Char,Set{Int}}()
    getConstraints!(guess,result,grays,yellows,greens)
    return grays,yellows,greens
end

function getConstraints!(guess,result,grays,yellows,greens)
    for ii = 1:5
        if result[ii] == 0
            if !any([guess[x]==guess[ii] for x in 1:(ii-1)])
                #This isn't quite right, but without a more accurate constraint for the multi-letter case I'll just ignore grays for second and following instances of a letter in a guess
                push!(grays,guess[ii])
            end
        elseif result[ii] == 1
            if !(guess[ii] in keys(yellows))
                yellows[guess[ii]] = Set{Int}()
            end
            push!(yellows[guess[ii]],ii)
        elseif result[ii] == 2
            if !(guess[ii] in keys(greens))
                greens[guess[ii]] = Set{Int}()
            end
            push!(greens[guess[ii]],ii)
        end
    end
    return grays,yellows,greens
end

function getResult(solution,guess)
    result = fill(0,5)
    for i = 1:5
        if !(guess[i] in solution) #gray
            result[i] = 0
            continue
        elseif guess[i]==solution[i] #green
            result[i] = 2
            continue
        else
            nthLetterInGuess = sum([guess[i] == guess[x] for x in 1:i])
            numTimesInSolution = sum([guess[i] == solution[x] for x in 1:5])
            if nthLetterInGuess > numTimesInSolution
                #if this is the n-th instances of this letter in the guess and there are fewer than n instances of this letter in the solution it is gray
                result[i] = 0
            else
                result[i] = 1
            end
        end
    end
    return result
end

function getNumBins(remainingAnswers,word)
    if true
        # score based on how many bins the 
        S = Set{Vector{Int}}()
        for ir = 1:length(remainingAnswers)
            push!(S,getResult(remainingAnswers[ir],word))
        end
        return length(S)
    else
        D = DefaultDict{Vector{Int}, Int}(0)
        for ir = 1:length(remainingAnswers)
            result = getResult(remainingAnswers[ir],word)
            D[result] += 1
        end

        score = 0.0
        for k in keys(D)
            p = D[k]/length(remainingAnswers)
            score -= p*log10(p)
        end

        return score
    end
    
end


function chooseAGuess(remainingAnswers::Vector{String},mode="all",pastGuesses::Vector{String}=[])
    function numLet(word)
        return length(unique([word[i] for i = 1:length(word)]))
    end
    remainingAnswers = setdiff(remainingAnswers,pastGuesses)

    if length(remainingAnswers) == 1
        return remainingAnswers[1],1
    elseif length(remainingAnswers) == 2
        if numLet(remainingAnswers[1]) > numLet(remainingAnswers[2])
            ix = 1
        else
            ix = 2
        end
        return remainingAnswers[ix],2
    end

    # Find the guess would generate the greatest number of unique results for each of the remaining words
    if mode == "all"
        wordList = words
    elseif mode == "answers"
        wordList = answers
    elseif mode == "remaining"
        wordList = remainingAnswers
    else
        wordList = words
        println("bad mode specifier; should be {\"all\",\"answers\",\"remaining\"}; using \"all\"")
    end
    wordList = cat(remainingAnswers,wordList,dims=1)


    lenVec = [numLet(w) for w in wordList]
    is5 = lenVec.==5
    if any(is5)
        wordList = wordList[is5]
    end

    numUniqueVec = fill(0,size(wordList))
    for iw = 1:length(wordList)
        numUniqueVec[iw] = getNumBins(remainingAnswers,wordList[iw])
        if numUniqueVec[iw] == length(remainingAnswers)
            #we've found a word that can distinguish all remaining answers; no need to keep going
            break
        end
    end
    maxIx = argmax(numUniqueVec)
    return wordList[maxIx], numUniqueVec[maxIx]
end


function sim(;solution=rand(answers),inputGuesses=[bestFirstGuess],mode="all",verbose=true)
    if !(solution in answers)
        println("bad solution -- choose one in the solution list")
        return (false,6)
    end

    solution = lowercase(solution)
    inputGuesses = [lowercase(x) for x in inputGuesses]
    
    if verbose
        println("Solution is $(uppercase(solution))")
        println()
    end

    let remainingAnswers = answers,pastGuesses=Vector{String}(),grays,yellows,greens,result,numGuess=0
        for i = 1:6
            if i <= length(inputGuesses)
                guess = inputGuesses[i];
                numBins = getNumBins(remainingAnswers,guess)
            else
                guess,numBins = chooseAGuess(remainingAnswers,mode,pastGuesses);
            end
            numGuess += 1
            if verbose
                println("/// Guess $i ///")
                println("Guessing $(uppercase(guess)) ($numBins bins)");
            end
            result = getResult(solution,guess);
            append!(pastGuesses,[guess])
            if verbose
                if sum(result)==10
                    println("You win!")
                else
                    print("Result is: ")
                    println(result');
                end
            end
            if sum(result)==10
                break
            end

            if i == 1
                grays,yellows,greens = getConstraints(guess,result);
            else
                getConstraints!(guess,result,grays,yellows,greens);
            end
            remainingAnswers = filterWords(grays,yellows,greens,pastGuesses);
            if verbose
                if !(solution in remainingAnswers)
                    println("something is wrong -- solution not in remainingAnswers")
                end 
                if length(remainingAnswers)==1
                    print("1 answer remains")
                else
                    print("$(length(remainingAnswers)) answers remain");
                end
                if length(remainingAnswers)<20
                    print(": ")
                    for a in remainingAnswers
                        print("$(uppercase(a)) ")
                    end
                end
                println()
                println()
            end
        end
        return(sum(result)==10,numGuess)
    end
end

function validateResultString(resultString)
    isValid = true
    if length(resultString) != 5
        isValid = false
    end
    if !all([x in ['0','1','2'] for x in resultString])
        isValid = false
    end
    return isValid
end

function validateGuess(guess)
    isValid = true
    if length(guess) != 5
        isValid = false;return
    end
    letters = 'a':'z'
    if !all([x in letters for x in guess])
        isValid = false;return
    end
    # if !(guess in words)
    #     isValid = false;return
    # end
    return isValid
end

function parseResultString(resultString)
    result = fill(0,5)
    ix = 1
    for character in resultString
        if character == '0'
            result[ix] = 0
            ix += 1
        elseif character == '1'
            result[ix] = 1
            ix += 1
        elseif character == '2'
            result[ix] = 2
            ix += 1
        end
    end
    if ix != 6
        println("Bad Result String!")
    end
    return result
end

function assist(mode="answers")
    let remainingAnswers,pastGuesses=Vector{String}(),grays,yellows,greens,result,numGuess=0

        for i = 1:6

            println("/// Guess $i ///")
            if i == 1
                bestGuess = bestFirstGuess
            else
                bestGuess,_ = chooseAGuess(remainingAnswers,mode,pastGuesses);
            end
            println("Suggested guess is: $(uppercase(bestGuess))")


            guess = ""
            println("Input your guess:")
            guess = readline()
            while !validateGuess(guess)
                println("Bad Guess. Input new guess:")
                println("Input your guess:")
                guess = readline()
                guess = lowercase(guess)
            end
            append!(pastGuesses,[guess])

            println("Input the result (gray=0, yellow=1, green=2):")
            resultString = readline()
            while !validateResultString(resultString)
                println("Bad Result String")
                println("Input the result (gray=0, yellow=1, green=2):")
                resultString = readline()
            end

            result = parseResultString(resultString)
            if sum(result)==10
                println("You win!")
                break
            end

            if i == 1
                grays,yellows,greens = getConstraints(guess,result);
            else
                getConstraints!(guess,result,grays,yellows,greens);
            end

            remainingAnswers = filterWords(grays,yellows,greens,pastGuesses);
            if length(remainingAnswers)==1
                print("1 answer remains")
            else
                print("$(length(remainingAnswers)) answers remain");
            end
            if length(remainingAnswers)<20
                print(": ")
                for a in remainingAnswers
                    print("$(uppercase(a)) ")
                end
            end
            println("\n")

        end
    end
end

using ProgressMeter
function testMode(mode)
    println("Testing mode = $mode")
    isWinVec = fill(false,size(answers))
    nGuessVec = fill(0,size(answers))
    p = Progress(length(answers))
    Threads.@threads for ii = 1:length(answers)
        isWinVec[ii],nGuessVec[ii] = sim(solution=answers[ii],mode=mode,verbose=false)
        next!(p)
    end

    print("Solved $(sum(isWinVec)) of $(length(isWinVec)) cases")
    println(" in an average of $(round(sum(nGuessVec[isWinVec])/sum(isWinVec),digits=2)) guesses")

    for i = 1:6
        println("$i guess: $(sum(nGuessVec[isWinVec] .== i))")
    end
    println("X guess: $(sum(.!isWinVec))")
    println()

    failedWords = answers[.!isWinVec]
    print("Failed Words: ")
    println(failedWords)

    return isWinVec,nGuessVec
end

function colormap(res)
    if res == 0
        c = :light_black
    elseif res == 1
        c = :yellow
    elseif res == 2
        c = :blue
    else
        c = :white
    end
    return c
end

function play()
    keyb = ["qwertyuiop","asdfghjkl","zxcvbnm"]
    solution = rand(answers)
    guessVec = []
    resultVec = []
    guess = ""
    D = DefaultDict{Char, Int}(-1)
    for i = 1:6
        println("\n\n/// Guess $i ///")
        println("Input your guess:")
        while true
            guess = readline()
            guess = lowercase(guess)
            if guess in words
                break
            end 
            println("   Guess not in word list. Input a new guess:")
        end
        push!(guessVec,guess)
        result = getResult(solution,guess);
        push!(resultVec,result)
        # [print("$x") for x in result]
        for j = 1:5
            D[guess[j]] = max(D[guess[j]],result[j])
        end
        println()
        for j = 1:length(resultVec)
            r = resultVec[j]
            g = guessVec[j]
            print("$j. ")
            for i = 1:length(r)
                printstyled(uppercase(g[i]),color=colormap(r[i]),bold=true)
            end
            println()
        end
        println()
        for j = 1:length(keyb)
            print(repeat(" ",j-1))
            row = keyb[j]
            for letter in row
                printstyled(uppercase(letter),color=colormap(D[letter]),bold=true)
                print(" ")
            end
            println()
        end
        if sum(result)==10
            println("\nYou win!")
            break
        elseif i==6
            println("\nYou lose! 😔\nSolution was $(uppercase(solution))")
        end
    end
end
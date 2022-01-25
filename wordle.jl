include("wordle-list.jl"); # words, answers
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


    lenVec = [numLet(w) for w in wordList]
    is5 = lenVec.==5
    if any(is5)
        wordList = wordList[is5]
    end

    numUniqueVec = fill(0,size(wordList))
    for iw = 1:length(wordList)
        S = Set{Vector{Int}}()
        for ir = 1:length(remainingAnswers)
            push!(S,getResult(remainingAnswers[ir],wordList[iw]))
        end
        numUniqueVec[iw] = length(S)
        if numUniqueVec[iw] == length(remainingAnswers)
            #we've found a word that can distinguish all remaining answers; no need to keep going
            break
        end
    end
    maxIx = argmax(numUniqueVec)
    return wordList[maxIx], numUniqueVec[maxIx]
end


function sim(;solution=rand(answers),inputGuesses::Vector{String}=["oater"],mode="all",verbose=true)
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

    let remainingAnswers,pastGuesses=Vector{String}(),grays,yellows,greens,result,numGuess=0
        for i = 1:6
            if i <= length(inputGuesses)
                guess = inputGuesses[i];
                numBins = 0;
            else
                guess,numBins = chooseAGuess(remainingAnswers,mode,pastGuesses);
            end
            numGuess += 1
            if verbose
                print("$i. Guessing $(uppercase(guess))");
                if (i > 1) && (i > length(inputGuesses))
                    println(" ($numBins bins)")
                else
                    println()
                end
            end
            result = getResult(solution,guess);
            append!(pastGuesses,[guess])
            if verbose
                print("   Result is: ")
                println(result');
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
                    print("   1 answer remains")
                else
                    print("   $(length(remainingAnswers)) answers remain");
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

import Plots
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

    Plots.histogram(nGuessVec[isWinVec]);
    Plots.title!("Distribution of Wins");
    Plots.gui()

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
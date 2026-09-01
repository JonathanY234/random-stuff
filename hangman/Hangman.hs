import System.Posix.Internals (puts)
hangmanStages :: [String]
hangmanStages = [
    "  +---+\n  |   |\n      |\n      |\n      |\n      |\n=========",
    "  +---+\n  |   |\n  O   |\n      |\n      |\n      |\n=========",
    "  +---+\n  |   |\n  O   |\n  |   |\n      |\n      |\n=========",
    "  +---+\n  |   |\n  O   |\n /|   |\n      |\n      |\n=========",
    "  +---+\n  |   |\n  O   |\n /|\\  |\n      |\n      |\n=========",
    "  +---+\n  |   |\n  O   |\n /|\\  |\n /    |\n      |\n=========",
    "  +---+\n  |   |\n  O   |\n /|\\  |\n / \\  |\n      |\n========="
    ]
main = do
    putStrLn "Welcome to Hangman"
    let guesses = 7 :: Int
    playgame guesses "hello" "_____"
    putStrLn "Goodbye"
playgame :: Int -> String -> String -> IO()
playgame attempts_left word guessed_word
    | attempts_left == 0 = putStrLn "You Lose!"
    | word == guessed_word = putStrLn "You Win"
    | otherwise = do

        guess <- getLetterInput
        if guess `elem` word
        then do
            putStrLn "Correct"
            let new_guessed_word = [if g /= '_' then g else if char == guess then char else '_' | (char, g) <- zip word guessed_word]

            putStrLn ("Word: " ++ new_guessed_word)
            playgame attempts_left word new_guessed_word
            -- Continue game logic...
        else do

            putStrLn ("Wrong guess! Attempts left: " ++ show (attempts_left-1))
            putStrLn ("Word: " ++ guessed_word)
            showHangmanArt attempts_left
            playgame (attempts_left-1) word guessed_word
getLetterInput :: IO Char
getLetterInput = do
    putStrLn "Enter your guess:"
    raw_guess <- getLine
    -- check for blank input
    if null raw_guess
        then do
            putStrLn "You didnt type a letter"
            getLetterInput
        else return (head raw_guess)
showHangmanArt :: Int -> IO()
showHangmanArt attempts_left = putStrLn (hangmanStages !! (7 - attempts_left))
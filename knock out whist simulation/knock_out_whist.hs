import System.Random (randomRIO)
import Control.Monad (foldM)
import Data.List (maximumBy)
import Data.Ord (comparing)

main :: IO ()
main = do
    print "Hello, Knockout Whist!"
    print $ pickTrumpSuit [Card Four Hearts, Card Two Clubs, Card Two Clubs, Card Six Diamonds]
    -- let trials = 5000000
    -- wins <- countWins trials
    -- putStrLn "Wins:"
    -- print wins
    -- putStrLn "Win Ratio:"
    -- print $ fromIntegral wins / fromIntegral trials


data Suit = Hearts | Diamonds | Clubs | Spades deriving (Eq, Enum, Bounded, Show)

data Rank = Two | Three | Four | Five | Six | Seven | Eight 
          | Nine | Ten | Jack | Queen | King | Ace
          deriving (Show, Eq, Ord, Enum, Bounded)

data Card = Card Rank Suit deriving (Eq, Show)
deck = [Card rank suit | rank <- [minBound .. maxBound], suit <- [minBound .. maxBound]]

pickNUniqueCards :: Int -> IO [Card]
pickNUniqueCards n = go n [] deck
  where
    go :: Int -> [Card] -> [Card] -> IO [Card]
    go 0 choices _ = return choices
    go n choices all = do
        i <- randomRIO (0, length all - 1)
        let choice = all !! i
        if choice `elem` choices
            then go n choices all --already chosen try again
            else go (n-1) (choice : choices) all

pickTrumpSuit :: [Card] -> Suit -- should give slightly more preference for more lower cards
pickTrumpSuit [] = Diamonds
pickTrumpSuit cards =
    let suits = [Hearts, Diamonds, Clubs, Spades]
        scores = map (\s -> sum [fromEnum r + 1 | Card r c <- cards, c == s]) suits
        argMax xs = fst $ maximumBy (comparing snd) (zip [0..] xs)
        i = argMax scores
    in suits !! i

playRound :: []
playTrick :: [[Card]] -> Suit -> Int -> Int
playTrick :: playersCards trump leader =
  let leaderChooseCard
    playerChooseCard



didTrumpWin :: [Card] -> Bool  --trump is the first in the list -- for the last round only
didTrumpWin (trumpCard : cards) = not $ any beatsTrump cards
    where 
        beatsTrump (Card r s) = (s == trumpSuit) && (r > trumpRank)
        Card trumpRank trumpSuit = trumpCard


countWins :: Int -> IO Int
countWins n = foldM go 0 [1..n]
  where
    go acc _ = do
      hand <- pickNUniqueCards 4-- [] deck
      return $ if didTrumpWin hand then acc + 1 else acc


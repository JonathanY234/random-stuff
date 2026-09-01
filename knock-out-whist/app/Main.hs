module Main where

--import System.Random
import System.Random.Shuffle (shuffleM)
import Data.List (maximumBy, partition, sort)
import Data.Ord (comparing)
import Control.Monad (zipWithM_)
--import System.IO.Unsafe (unsafePerformIO)

data Suit = Hearts | Diamonds | Clubs | Spades
    deriving (Show, Eq, Ord, Enum, Bounded)

data Rank = Two | Three | Four | Five | Six | Seven | Eight | Nine | Ten | Jack | Queen | King | Ace
    deriving (Show, Eq, Ord, Enum, Bounded)

data Card = Card Rank Suit
    deriving (Show, Eq, Ord)

type Hand = [Card]

data RoundResult = Won | Lost | Draw
    deriving (Show, Eq)

numPlayers :: Int
numPlayers = 4

sortedDeck :: [Card]
sortedDeck = [Card rank suit | rank <- [Two .. Ace], suit <- [Hearts .. Spades]]

shuffleDeck :: [Card] -> IO [Card]
shuffleDeck = shuffleM

-- mostCommon :: (Ord a) => [a] -> a
-- mostCommon xs =
--     let grouped = group (sort xs)
--     in fst $ maximumBy (comparing length) [(head g, length g) | g <- grouped]

-- Choose Trump from Hand
rankValue :: Rank -> Int
rankValue r = fromEnum r + 1

suitStats :: Hand -> [(Suit, (Int, Int))]
suitStats hand =
    let suits = [Hearts, Diamonds, Clubs, Spades]
        countAndSum s = (s, ( length [ () | Card _ suit <- hand, suit == s ], sum [ rankValue rank | Card rank suit <- hand, suit == s ] ) )
    in map countAndSum suits

chooseTrump :: Hand -> Suit
chooseTrump hand =
    fst $ maximumBy (comparing (\(_, (count, total)) -> (count, total))) (suitStats hand)

-- Deal Hands
dealHands :: Int -> [Card] -> [Hand]
dealHands numCards deck = [ take numCards (drop (i*numCards) deck) | i <- [0..numPlayers-1] ]

playRound :: [Card] -> Int -> RoundResult
playRound shuffledDeck roundNum =
    let hands = dealHands roundNum shuffledDeck

        -- the first player in the list is trump chooser player
        trumpSuit = chooseTrump (head hands)

        playTricks :: Int -> Suit -> Int -> [Hand] -> ([Int], [Hand])
        playTricks _ _ 0 hands' = ([], hands')  -- base case: no tricks left
        playTricks leader trumpSuit' n hands' =
            let (winner, updatedHands) = playTrick leader trumpSuit' hands'
                (restWinners, finalHands) = playTricks winner trumpSuit' (n-1) updatedHands
            in (winner : restWinners, finalHands)

        (winners, _) = playTricks 0 trumpSuit numPlayers hands

        -- Count how many tricks each player won
        counts p = length [ () | w <- winners, w == p ]
        player0Count = counts 0
        otherCounts = [ counts p | p <- [1 .. numPlayers - 1] ]

        maxOther = if null otherCounts then 0 else maximum otherCounts

    in if player0Count > maxOther then Won
        else if player0Count == maxOther then Draw
        else Lost

playTrick :: Int -> Suit -> [Hand] -> (Int, [Hand])
playTrick leader trump hands =
    let
        -- Rotate hands so leader goes first, preserving relative order
        rotatedHands = rotateToLeader leader hands

        -- Leader plays
        (leadCard, leaderHand') = leaderChooseCard (head rotatedHands) trump

        -- Followers play in order
        playFollowers :: [Hand] -> [Card] -> ([Card], [Hand])
        playFollowers [] played = (played, [])
        playFollowers (h:hs) played =
            let (card, h') = followerChooseCard h trump played
                (cards, hands') = playFollowers hs (played ++ [card])
            in (cards, h' : hands')

        (playedCards, followerHands') = playFollowers (tail rotatedHands) [leadCard]

        updatedRotatedHands = leaderHand' : followerHands'

        -- Determine winner relative to rotated list
        winnerRelative = trickWinner trump playedCards

        -- Map back to original player indexing
        winner = (leader + winnerRelative) `mod` numPlayers

        updatedHands = unrotateToLeader leader updatedRotatedHands

    in (winner, updatedHands)

rotateToLeader :: Int -> [a] -> [a]
rotateToLeader leader xs =
    let (before, after) = splitAt leader xs
    in after ++ before

unrotateToLeader :: Int -> [a] -> [a]
unrotateToLeader leader xs =
    let (before, after) = splitAt (numPlayers - leader) xs
    in after ++ before

leaderChooseCard :: Hand -> Suit -> (Card, Hand)
leaderChooseCard [] _ = error "leaderChooseCard: empty hand (state bug upstream)"
leaderChooseCard hand trump =
    let (trumps, nonTrumps) = partition (\(Card _ s) -> s == trump) hand
        aceOfTrump = filter (\(Card r s) -> r == Ace && s == trump) hand
        highestNonTrump = maximum nonTrumps
        highestTrump = maximum trumps

    in case aceOfTrump of
        (ace:_) -> (ace, filter (/= ace) hand) -- has aceOfTrump play it
        [] -> if not (null nonTrumps)
                then (highestNonTrump, filter (/= highestNonTrump) hand)
                else (highestTrump, filter (/= highestTrump) hand)

followerChooseCard :: Hand -> Suit -> [Card] -> (Card, Hand)
followerChooseCard hand trump played =
    let (Card _ leaderSuit) = head played

        -- Split hand
        (leaderCards, rest) = partition (\(Card _ s) -> s == leaderSuit) hand
        (trumps, others)    = partition (\(Card _ s) -> s == trump) rest

        -- Cards already played of relevant suits
        playedLeader = [c | c@(Card _ s) <- played, s == leaderSuit]
        playedTrumps = [c | c@(Card _ s) <- played, s == trump]

        -- Highest cards already played
        highestLeader = if null playedLeader then Nothing else Just (maximum playedLeader)
        highestTrump  = if null playedTrumps then Nothing else Just (maximum playedTrumps)

        -- Helpers
        higherThan x = filter (> x)
        chooseLowestNonTrump = if not (null others) then minimum others else minimum trumps
        remove c = filter (/= c) hand

    in
        -- Case 1: must follow suit
        if not (null leaderCards) then
            case highestLeader of
                Just h ->
                    let beating = higherThan h leaderCards
                    in if not (null beating)
                        then let c = minimum beating in (c, remove c)
                        else let c = minimum leaderCards in (c, remove c)
                Nothing ->
                    let c = minimum leaderCards in (c, remove c) -- not possible to reach here there must be a leader

        -- Case 2: no leader suit, use trump if possible, otherwise play lowest non-trump
        else
            case highestTrump of
                Just h -> let beating = higherThan h trumps
                          in if not (null beating)
                                then let c = minimum beating in (c, remove c)
                                else let c = chooseLowestNonTrump in (c, remove c)
                Nothing -> let c = chooseLowestNonTrump in (c, remove c)

-- who won
trickWinner :: Suit -> [Card] -> Int
trickWinner trump cards =
    let
        (Card _ leadSuit) = head cards
        -- Filter trump cards first
        trumpsPlayed = [(i,c) | (i,c@(Card _ s)) <- zip [0..] cards, s == trump]
        leadPlayed   = [(i,c) | (i,c@(Card _ s)) <- zip [0..] cards, s == leadSuit]

        -- Choose which suit determines the winner
        relevantCards = if not (null trumpsPlayed) then trumpsPlayed else leadPlayed

        -- Find index of highest card
        (winnerIndex, _) = foldl1 (\acc@(_,c1) curr@(_,c2) -> if c2 > c1 then curr else acc) relevantCards
    in winnerIndex

-- run tests
data Stats = Stats
    { wins   :: Int
    , losses :: Int
    , draws  :: Int
    } deriving Show

updateStats :: Stats -> RoundResult -> Stats
updateStats s r = case r of
    Won  -> s { wins   = wins s + 1 }
    Lost -> s { losses = losses s + 1 }
    Draw -> s { draws  = draws  s + 1 }

runRoundTests :: Int -> [Card] -> Int -> IO Stats
runRoundTests n theSortedDeck roundNum = do
    results <- mapM (\_ -> do
        deck <- shuffleDeck theSortedDeck
        return (playRound deck roundNum)
        ) [1..n]

    let stats = foldl updateStats (Stats 0 0 0) results
    return stats

formatPercentages :: Stats -> String
formatPercentages (Stats w l d) =
    let n = fromIntegral (w + l + d)
        pct x = (fromIntegral x / n) * 100

        fmt x = show (fromIntegral (round (x * 100) :: Int) / 100)

        pw = fmt (pct w)
        pl = fmt (pct l)
        pd = fmt (pct d)

    in "Win: " ++ pw ++ "%  "
    ++ "Loss: " ++ pl ++ "%  "
    ++ "Draw: " ++ pd ++ "%"
printRound :: Int -> Stats -> IO ()
printRound roundNum stats = do
    putStrLn $ "Round: " ++ show roundNum
    putStrLn $ formatPercentages stats

main :: IO ()
main = do
    -- deck <- shuffleDeck sortedDeck

    -- print $ playRound deck 2


    let roundNums = [3..7]
    -- allStats <- mapM (runRoundTests 10000 sortedDeck) roundNums
    -- mapM_ (print . formatPercentages) allStats

    allStats <- mapM (runRoundTests 10000 sortedDeck) roundNums
    zipWithM_ printRound roundNums allStats

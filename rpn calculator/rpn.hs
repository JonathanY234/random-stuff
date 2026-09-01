main = do
    rpnTokens <- getInput
    print rpnTokens

    case calcRPN rpnTokens [] of
        Left err -> putStrLn $ "Error: " ++ err
        Right result -> print result

getInput :: IO [String]
getInput = do
    putStrLn "Enter a valid rpn:"
    words <$> getLine

calcRPN :: [String] -> [Double] -> Either String Double
calcRPN [] [result] = Right result
calcRPN [] _ = Left "Stack did not end with exactly one result"
calcRPN (token:rest) stack =
    case token of
        "+" -> binaryOp (+) rest stack
        "-" -> binaryOp (-) rest stack
        "*" -> binaryOp (*) rest stack
        "/" -> binaryOpSafe (/) rest stack
        _   -> case reads token :: [(Double, String)] of
                  [(num, "")] -> calcRPN rest (num : stack)
                  _           -> Left $ "Invalid token: " ++ token

-- For operators like + - *
binaryOp :: (Double -> Double -> Double) -> [String] -> [Double] -> Either String Double
binaryOp op rest (x:y:xs) = calcRPN rest (op y x : xs)
binaryOp _ _ _ = Left "Not enough operands"

-- For operators like /
binaryOpSafe :: (Double -> Double -> Double) -> [String] -> [Double] -> Either String Double
binaryOpSafe op rest (0:y:xs) = Left "Division by zero"
binaryOpSafe op rest (x:y:xs) = calcRPN rest (op y x : xs)
binaryOpSafe _ _ _ = Left "Not enough operands"

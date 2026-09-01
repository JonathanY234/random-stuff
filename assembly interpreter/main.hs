import qualified Data.Vector as V
import Data.Vector ((!))
import Control.Monad (when)
import System.Environment (getArgs)
import System.Exit (die)


type Registers = V.Vector Int

data CPUState = CPUState {pc :: Int, generalRegs :: Registers} deriving Show

data Instruction = Instruction{opcode :: String, operand1 :: Int, operand2 :: Int} deriving Show

numberOfRegs :: Int
numberOfRegs = 10

main = do
    args <- getArgs
    programFilePath <- case args of
        (filePath:_) -> return filePath
        []           -> die "Please provide a file path."
    
    result <- loadInstructions programFilePath
    instructions <- case result of
        Left err -> do
            putStrLn $ "Error: " ++ err
            fail "Parsing failed, exiting."
        Right instrs -> return instrs
    print instructions

    let initialRegs = V.replicate numberOfRegs 0
        initialCPUState = CPUState {pc = 0, generalRegs = initialRegs}
    print initialCPUState
    cpuCycle instructions initialCPUState 0
    
parseInstruction :: Int -> String -> Either String Instruction
parseInstruction instNum line =
    case words line of 
        [oc, opr1Str, opr2Str] ->
            case (reads opr1Str, reads opr2Str) of
                ([(opr1, "")], [(opr2, "")]) -> Right (Instruction oc opr1 opr2)
                _ -> Left ("Line" ++ show instNum ++ " operands must be numbers")
        _ -> Left ("Line" ++ show instNum ++ "Instruction must have 3 words")

parseWithLineNums :: [String] -> Either String [Instruction]
parseWithLineNums = traverse (uncurry parseInstruction) . zip [1..]

loadInstructions :: FilePath -> IO (Either String [Instruction])
loadInstructions filePath = do
    contents <- readFile filePath
    return $ parseWithLineNums (lines contents)    

cpuCycle :: [Instruction] -> CPUState -> Int -> IO ()
cpuCycle instrs cpuState cycleCount = do
    let pcIndex = pc cpuState
    if pcIndex >= length instrs then
        putStrLn "Program finished."
    else do
        let instr = instrs !! pcIndex
        putStrLn ("___________" ++ show cycleCount)
        print cpuState
        print instr
        cpuState' <- case opcode instr of
            "LDR" -> return $ instrLDR cpuState instr
            "MOV" -> return $ instrMOV cpuState instr
            "ADD" -> return $ instrADD cpuState instr
            "SUB" -> return $ instrSUB cpuState instr
            "JMP" -> return $ instrJMP cpuState instr
            "JPZ" -> return $ instrJPZ cpuState instr
            "JPP" -> return $ instrJPP cpuState instr
            "HLT" -> do
                putStrLn "HLT: Halting execution."
                return cpuState
            "PRT" -> do
                instrPRT cpuState instr
                return $ cpuState { pc = pc cpuState + 1 }
            _     -> do
                putStrLn $ "Unknown instruction: " ++ opcode instr
                return cpuState
        -- Only recurse if not HLT
        when (opcode instr /= "HLT") $
            cpuCycle instrs cpuState' (cycleCount +1)

instrLDR :: CPUState -> Instruction -> CPUState
instrLDR cpuState instr =
    let regIndex = operand1 instr
        value = operand2 instr -- i just want to get that into value out of the ADT
        regs' = generalRegs cpuState V.// [(regIndex, value)]
        pc' = pc cpuState + 1
    in cpuState {pc = pc', generalRegs = regs'}

instrMOV :: CPUState -> Instruction -> CPUState
instrMOV cpuState instr =
    let regIndex1 = operand1 instr
        regIndex2 = operand2 instr
        value = generalRegs cpuState V.! regIndex2
        regs' = generalRegs cpuState V.// [(regIndex1, value)]
        pc' = pc cpuState + 1
    in cpuState {pc = pc', generalRegs = regs'}

instrADD :: CPUState -> Instruction -> CPUState
instrADD cpuState instr =
    let regIndex1 = operand1 instr
        regIndex2 = operand2 instr
        addVal = (generalRegs cpuState V.! regIndex1) + (generalRegs cpuState V.! regIndex2)
        regs' = generalRegs cpuState V.// [(regIndex1, addVal)]
        pc' = pc cpuState + 1
    in cpuState {pc = pc', generalRegs = regs'}

instrSUB :: CPUState -> Instruction -> CPUState
instrSUB cpuState instr =
    let regIndex1 = operand1 instr
        regIndex2 = operand2 instr
        subVal = (generalRegs cpuState V.! regIndex1) - (generalRegs cpuState V.! regIndex2)
        regs' = generalRegs cpuState V.// [(regIndex1, subVal)]
        pc' = pc cpuState + 1
    in cpuState {pc = pc', generalRegs = regs'}

instrJMP :: CPUState -> Instruction -> CPUState
instrJMP cpuState instr = cpuState {pc = operand1 instr -1} -- -1 to account for 0 based indexing of lists

instrJPZ :: CPUState -> Instruction -> CPUState
instrJPZ cpuState instr =
    let regIndex = operand1 instr
        value = generalRegs cpuState V.! regIndex
        jumpTarget = if value == 0 then operand2 instr - 1 else pc cpuState + 1
    in cpuState {pc = jumpTarget}

instrJPP :: CPUState -> Instruction -> CPUState
instrJPP cpuState instr =
    let regIndex = operand1 instr
        value = generalRegs cpuState V.! regIndex
        jumpTarget = if value > 0 then operand2 instr - 1 else pc cpuState + 1
    in cpuState {pc = jumpTarget}

instrPRT :: CPUState -> Instruction -> IO ()-- CPUState
instrPRT cpuState instr = do
    let regIndex = operand1 instr
        value = generalRegs cpuState V.! regIndex
    putStrLn ("PRT: " ++ show value)
    --let pc' = pc cpuState + 1
    --return cpuState {pc = pc'}
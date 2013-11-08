import System.Environment
import System.IO
import Text.Regex
import Data.Maybe
import Control.Monad
import Data.Word (Word8)
import Data.Char (toUpper)

data RAM = RAMMacro Int String | RAMValue Int Int deriving Show

data Instruction = Instr0Op { instr :: String } |
                   Instr1Op { instr :: String, op1 :: String } |
                   Instr2Op { instr :: String, op1 :: String, op2 :: String }
                   deriving Show

newtype ValidatedInstr = Validated Instruction

instr0Op = map mkRegex ["NOP", "HLT", ".*"]
instr1Op = map mkRegex ["GOTO", "JMPZ", "JMPNZ", "NOT", "NEG", "DB"]
instr2Op = map mkRegex ["LOAD", "STORE", "MOV", "AND", "OR", "XOR", "ADD",
                        "SUB", "MUL"]
regs = map mkRegex ["AX", "BX", "CX", "DX"]

main = do
        args <- getArgs
        progName <- getProgName
        if length args /= 2
        then do
            putStrLn "Wrong number of arguments. Usage:"
            putStrLn $ progName ++ " input_file output_file"
        else do
            putStrLn "cn-asm started..."
            transform (args !! 0) (args !! 1)
            

transform inFile outFile = do
        contents <- readFile inFile

        outHandle <- openFile outFile WriteMode
        mapM_ (hPutStrLn outHandle) (words contents)
        hClose outHandle

isInstr0Op word = null $ filter isJust $ map (\exp -> matchRegex exp word) instr0Op
isInstr1Op word = null $ filter isJust $ map (\exp -> matchRegex exp word) instr1Op
isInstr2Op word = null $ filter isJust $ map (\exp -> matchRegex exp word) instr2Op
isReg word = null $ filter isJust $ map (\exp -> matchRegex exp word) regs
isLabel word = isJust $ matchRegex (mkRegex ".*") word

transformToAddr word
        | isLabel word = word
        | otherwise = show (read word::Word8)

getValidatedInstructions words = reverse $ map validateInstr 
                                                (getInstructions [] words)
validateInstr Instr0Op {instr = x} = Validated Instr0Op {instr = x}
validateInstr Instr1Op {instr = x,
                        op1 = o1}
        | x == "NOT" || x == "NEG" = if isReg oUppr
                                        then Validated Instr1Op {instr = x,
                                                                 op1 = oUppr}
                                        else error "Invalid instruction"
        | x == "DB" = if isLabel oUppr
                        then Validated Instr1Op {instr = x, 
                                                 op1 = oUppr}
                        else error "Invalid instruction"
        | otherwise = Validated Instr1Op {instr = x,
                                          op1 = transformToAddr oUppr}
        where oUppr = toUpperString o1

validateInstr Instr2Op {instr = x,
                        op1 = o1,
                        op2 = o2}
        | x == "LOAD" = if isReg o1Uppr
                            then Validated Instr2Op {instr = x,
                                                     op1 = o1Uppr,
                                                     op2 = transformToAddr o2}
                            else error "Invalid instruction"
        | x == "STORE" = if isReg o2Uppr
                            then Validated Instr2Op {instr = x,
                                                     op1 = transformToAddr o1,
                                                     op2 = o2Uppr}
                            else error "Invalid instruction"
        | otherwise = if isReg o1Uppr && isReg o2Uppr
                            then Validated Instr2Op {instr = x,
                                                     op1 = o1Uppr,
                                                     op2 = o2Uppr}
                            else error "Invalid instruction"
        where o1Uppr = toUpperString o1 
              o2Uppr = toUpperString o2

getInstructions :: [Instruction] -> [String] -> [Instruction]
getInstructions instructions [] = instructions
getInstructions instructions (word : words)
        | isInstr0Op wordUpr = getInstructions 
                                (Instr0Op {instr = wordUpr}
                                 : instructions) 
                                words
    where wordUpr = toUpperString word
getInstructions instructions (word1 : word2 : words)
        | isInstr1Op wordUpr = getInstructions 
                                (Instr1Op {instr = wordUpr,
                                           op1   = word2}
                                 : instructions) 
                                words
    where wordUpr = toUpperString word1
getInstructions instructions (word1 : word2 : word3 : words)
        | isInstr2Op wordUpr = getInstructions 
                                (Instr2Op {instr = wordUpr,
                                           op1 = word2,
                                           op2 = word3}
                                 : instructions) 
                                words
    where wordUpr = toUpperString word1

toUpperString :: [Char] -> [Char]
toUpperString s = map toUpper s

ramToString (RAMMacro addr val) = "ram[" ++ (show addr) ++ "]=" ++ val ++ ";"
ramToString (RAMValue addr val) = "ram[" ++ (show addr) ++ "]=" ++
                                   (show val)  ++ ";"

{-
main = do
        args <- getArgs  
        progName <- getProgName  
        putStrLn "The arguments are:"  
        mapM putStrLn args  
        putStrLn "The program name is:"  
        putStrLn progName  
        let list = []
        handle <- openFile "test.txt" ReadMode
        contents <- hGetContents handle
        let singlewords = words contents
        print singlewords
        hClose handle
-}


-- | "Tokenizer" contains all the functions for tokenization of Substance
--   programs and patterns as part of the syntactic sugar mechanism
--    Author: Dor Ma'ayan, August 2018

{-# OPTIONS_HADDOCK prune #-}
module Tokenizer where
--module Main (main) where -- for debugging purposes

import Utils
import System.Process
import Control.Monad (void)
import Data.Void
import System.IO -- read/write to file
import System.Environment
import Control.Arrow ((>>>))
import System.Random
import Debug.Trace
import Data.Functor.Classes
import Data.List
import Data.Maybe (fromMaybe)
import Data.Typeable
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Expr
import Env

import qualified Data.Map.Strict as M
import qualified Text.Megaparsec.Char.Lexer as L
import qualified SubstanceTokenizer         as T

------------------------------ Tokenization ------------------------------------
-- | Get as an input from and to string notataions and returns refined tokenized
--   versions of them

-- | Tokenize the given string using the Substance tokenizer, returns pure token
--   list as it is given from the tokenizer itself
tokenize :: String -> [T.Token]
tokenize = T.alexScanTokens

-- | Translate string notation patterns into tokenized patterns which ignores
--   spaces and properly recognize patterns and Dsll entities
translatePatterns :: (String,String) -> VarEnv -> ([T.Token],[T.Token])
translatePatterns (fromStr, toStr) dsllEnv =
  let from = foldl (refineDSLLToken dsllEnv) [] (tokenize fromStr)
      patterns = filter notPatterns from
      to = foldl (refinePaternToken patterns) [] (tokenize toStr)
  in (filter spaces from, filter spaces to)

notPatterns :: T.Token -> Bool
notPatterns (T.Pattern t) = True
notPatterns token = False

spaces :: T.Token -> Bool
spaces T.Space  = False
spaces token = True

refinePaternToken :: [T.Token] -> [T.Token] -> T.Token -> [T.Token]
refinePaternToken patterns tokens (T.Var v) =
   if T.Pattern v `elem` patterns
    then tokens ++ [T.Pattern v]
    else tokens ++ [T.Var v]

refinePaternToken patterns tokens t = tokens ++ [t]


refineDSLLToken :: VarEnv -> [T.Token] -> T.Token -> [T.Token]
refineDSLLToken dsllEnv tokens (T.Var v) = if isDeclared v dsllEnv then
                                          tokens ++ [T.DSLLEntity v]
                                       else tokens ++ [T.Pattern v]
refineDSLLToken dsllEnv tokens t = tokens ++ [t]

-- |This function identify the pattern vars in the sugared notatation in the
--  StmtNotation in the DSLL
identifyPatterns :: [T.Token] -> [T.Token] -> [T.Token]
identifyPatterns tokensSugared tokenDesugared =
   foldl (identifyPattern tokenDesugared) [] tokensSugared

identifyPattern :: [T.Token] -> [T.Token] -> T.Token -> [T.Token]
identifyPattern tokenDesugared tokensSugared (T.Var v) =
   if T.Var v `elem` tokenDesugared then
     tokensSugared ++ [T.Pattern v]
  else
    tokensSugared ++ [T.Var v]
identifyPattern tokenDesugared tokensSugared token = tokensSugared ++ [token]

-- | Retranslate a token list into a program
reTokenize :: [T.Token] -> String
reTokenize = foldl translate ""

-- | Translation function from a specific token back into String
--   In use after the notation replacements in order to translate back to
--   a Substance program
translate :: String -> T.Token -> String
translate prog T.Bind = prog ++ ":="
translate prog T.NewLine = prog ++ "\n"
translate prog T.PredEq = prog ++ "<->"
translate prog T.ExprEq = prog ++ "="
translate prog T.Comma = prog ++ ","
translate prog T.Lparen = prog ++ "("
translate prog T.Rparen = prog ++ ")"
translate prog T.Space = prog ++ " "
translate prog (T.Sym c) = prog ++ [c]
translate prog (T.Var v) = prog ++ v
translate prog (T.Comment c) = prog ++ c
translate prog (T.DSLLEntity d) = prog ++ d
translate prog (T.Pattern p) = prog ++ p
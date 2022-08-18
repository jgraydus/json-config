module Config.Internal where

import           Control.Lens (both, over)
import           Data.Aeson
import           Data.Aeson.KeyMap (unionWith)
import           Data.Aeson.Parser.Internal (jsonEOF)
import qualified Data.Attoparsec.Lazy as L
import qualified Data.ByteString.Lazy as LBS
import qualified Data.Map as M
import           Data.Maybe (mapMaybe)
import           Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as E
import qualified Data.Text.IO as TIO
import           System.Environment (getEnvironment) 
import           Text.Glabrous
import           Text.Glabrous.Types (Token(..))

readConfigFile :: FilePath -> IO (Either String LBS.ByteString)
readConfigFile filePath = do
  env <- getEnvironment
  raw <- replaceVariables env <$> TIO.readFile filePath
  return $ LBS.fromStrict . E.encodeUtf8 <$> raw

replaceVariables :: [(String,String)] -> Text -> Either String Text
replaceVariables env raw = do
   tmplt <- fromText raw
   let (renames, defaults) = preprocessTags $ tagsOf tmplt
       e = M.fromList $ over both T.pack <$> env
       d = M.fromList defaults
       ctx = fromList $ M.toList $ M.union e d
   return $ process (tagsRename renames tmplt) ctx

{- if a tag defines a default value with the syntax
 -     {{variable || defaultValue}}
 - then return two pairs. the first pair is the original tag 
 - text along with the tag text with the '|| defaultValue' part 
 - removed. the second pair is the new tag (same as _2 of first pair)
 - along with the default value
 -}
preprocessTag :: Token -> Maybe ((Text, Text), (Text,Text))
preprocessTag (Tag oldTxt) = 
  case T.splitOn "||" oldTxt of 
    [t, val] -> 
      let newTxt = T.strip t
      in Just ((oldTxt, newTxt), (newTxt, T.strip val))
    _ -> Nothing
preprocessTag _ = Nothing

preprocessTags :: [Token] -> ([(Text,Text)], [(Text, Text)])
preprocessTags = unzip . mapMaybe preprocessTag

merge :: Value -> Value -> Value 
merge (Object a) (Object b) = Object $ unionWith merge a b
merge _ v = v

decodeWithBetterErrorMessage :: LBS.ByteString -> Either String Value
decodeWithBetterErrorMessage s =
    case L.parse jsonEOF s of
      L.Done _ v     -> Right v
      L.Fail notparsed _ _ -> Left (buildMsg notparsed)
  where
    buildMsg :: LBS.ByteString -> String
    buildMsg notYetParsed =
      let txt = E.decodeUtf8 $ LBS.toStrict s
          numbers = T.pack . (++ "| ") . show <$> [(1 :: Int)..]
          txtLines = zipWith T.append numbers (T.lines txt)
          unparsedTxtLines = T.lines $ E.decodeUtf8 $ LBS.toStrict notYetParsed
          n = length txtLines - length unparsedTxtLines
          window = take 7 $ drop (length txtLines - length unparsedTxtLines - 4) txtLines
      in T.unpack $ T.unlines $ T.pack ("JSON syntax error at line " ++ show n) : window


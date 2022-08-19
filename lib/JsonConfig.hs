module JsonConfig (
    readConfig
) where

import JsonConfig.Constants
import JsonConfig.Internal
import Data.Aeson
import Data.Char (toLower)

type ConfigFileDirectoryPath = FilePath
type EnvironmentName = String
type ErrorMessage = String

{- reads the default config file, merges in the overrides in environment-specific
 - config file, replaces any {{ENVIRONMENT_VARIABLE}} with values from environment 
 - and then parses into the specified data type -}
readConfig
  :: FromJSON a
  => ConfigFileDirectoryPath
  -> EnvironmentName
  -> IO (Either ErrorMessage a)
readConfig configFileDir environmentName = do

  let defaultConfigFile     = configFileDir <> "/" <> defaultConfigFileName
      environmentConfigFile = configFileDir <> "/" <> (mkConfigFileName environmentName)

  Right defaultConfig     <- readConfigFile defaultConfigFile
  Right environmentConfig <- readConfigFile environmentConfigFile

  let defaultConfigJson :: Either String Value = 
        decodeWithBetterErrorMessage defaultConfig
      environmentConfigJson :: Either String Value = 
        decodeWithBetterErrorMessage environmentConfig
      mergedConfigJson = merge <$> defaultConfigJson <*> environmentConfigJson

  case fromJSON <$> mergedConfigJson of
    Left err          -> return $ Left err
    Right (Error err) -> return $ Left err
    Right (Success x) -> return $ Right x

mkConfigFileName :: EnvironmentName -> FilePath
mkConfigFileName = (<> ".json") . (fmap toLower)


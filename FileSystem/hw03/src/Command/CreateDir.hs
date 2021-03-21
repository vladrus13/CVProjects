module Command.CreateDir
  ( run,
    commandM,
  )
where

import Control.Monad (when)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Except (ExceptT)
import Control.Monad.Trans.Reader (ReaderT)
import Control.Monad.Trans.State (State, get, put)
import Control.Monad.Trans.Writer (WriterT)
import Data.Time.Clock (UTCTime)
import Errors (Error (Another, FileAlreadyExists, UnexpectedError))
import Options.Applicative
  ( CommandFields,
    Mod,
    Parser,
    command,
    help,
    info,
    metavar,
    progDesc,
    strArgument,
  )
import System.Directory.Internal (Permissions (Permissions))
import System.FilePath.Posix ((</>))
import Types (Command (CreateDir), DirectoryInfo (..), FileSystem (Folder), FileSystemContainer)
import Utils (fileSystemNewFile, fileSystemTo, getDirectoryFullPath, throwError, toDirectory)

-- | Run create directory command with name
run :: String -> ReaderT UTCTime (WriterT String (ExceptT Error (State FileSystemContainer))) ()
run name = do
  when ('/' `elem` name) (throwError $ Another $ "Bad character '/' on name of file " ++ name)
  lift . lift . lift $ toDirectory
  fz <- lift . lift . lift $ get
  let directoryInfo =
        DirectoryInfo
          { directoryName = name,
            directoryPath = getDirectoryFullPath fz </> name,
            directoryPermission = Permissions True True False True
          }
  case fileSystemTo name fz of
    Nothing -> case fileSystemNewFile (Folder directoryInfo []) fz of
      Just fz' -> lift . lift . lift $ put fz'
      Nothing -> throwError UnexpectedError
    Just _ -> throwError $ FileAlreadyExists name

-- | Parser part for create directory
commandM :: Mod CommandFields Command
commandM = command "create-folder" (info optionsM (progDesc "Create folder"))

-- | Info part for create directory
optionsM :: Parser Command
optionsM = CreateDir <$> strArgument (metavar "<folder>" <> help "Name of folder to create")
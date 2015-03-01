module Curry.State where

import           Curry.Common
import           Curry.Parsers.Torrent

import           Control.Concurrent.STM
import           Control.Monad.Reader
import qualified Data.ByteString as B
import qualified Data.Map as M
import           Network.Socket
import           System.IO

----------------------------------------
-- OUR MONAD STACK (likely to change as
-- I decide to make the concurrency
-- control more granular.
----------------------------------------

type Curry = Reader Environment

----------------------------------------
-- COMMON TO THE ENTIRE INSANCE
----------------------------------------

data Environment = Environment
    { config    :: Config
    , identity  :: Identity
    , metaInfo  :: MetaInfo
    , currPiece :: TVar (M.Map Chunk B.ByteString)
    , pieceMap  :: TVar (M.Map Integer (Maybe  Handle))
    , peers     :: TVar [Peer]
    } deriving Show

data Config = Config
    { minPeers :: Integer
    , maxPeers :: Integer
    } deriving Show

data Identity = Identity
    { port       :: Integer -- port listening on
    , pid        :: B.ByteString -- out peer id (random)
    , key        :: B.ByteString -- our key (random)
    } deriving Show

-- Information about a part of a piece
data Chunk = Chunk
    { index :: Integer
    , start :: Integer
    , end   :: Integer
    } deriving (Show, Eq, Ord)

-- Information about a specific peer.
data Peer = Peer
    { socket  :: Socket
    , theirID :: B.ByteString -- out peer id (random)
    , mut     :: TVar MutPeer
    } deriving Show

-- What a specific peer thread has
data MutPeer = MutPeer
    { status  :: Status
    , has     :: (M.Map Integer Bool)
    , up      :: Integer
    , down    :: Integer
    } deriving Show

data Status = Status
    { choked      :: Bool
    , choking     :: Bool
    , interesting :: Bool
    , interested  :: Bool
    } deriving Show

----------------------------------------
-- STATES FOR SPECIFIC THREADS (as the
-- codebase grows, these will be moved)
----------------------------------------

data CommSt = CommSt
    { trackerID   :: B.ByteString -- our tracker id
    , interval    :: Integer -- from tracker
    , minIntervel :: Integer -- from tracker
    }

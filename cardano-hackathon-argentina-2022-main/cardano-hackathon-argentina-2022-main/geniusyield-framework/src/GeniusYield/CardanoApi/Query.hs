module GeniusYield.CardanoApi.Query (
    -- * Low-level query runners
    queryCardanoMode,
    queryAlonzoEra,
    queryBabbageEra,
    queryUTxO,
    -- * Exception
    CardanoQueryException (..),
) where

import           Control.Exception   (Exception, throwIO)

import qualified Cardano.Api         as Api
import qualified Cardano.Api.Shelley as Api.S

import           GeniusYield.Types

-------------------------------------------------------------------------------
-- Exception
-------------------------------------------------------------------------------

newtype CardanoQueryException = CardanoQueryException String
  deriving stock (Show)
  deriving anyclass (Exception)

-------------------------------------------------------------------------------
-- Low-level query runners
-------------------------------------------------------------------------------

queryCardanoMode :: Api.LocalNodeConnectInfo Api.CardanoMode -> Api.QueryInMode Api.CardanoMode a -> IO a
queryCardanoMode info q = do
    e <- Api.queryNodeLocalState info Nothing q
    case e of
        Left err -> throwIO $ CardanoQueryException $ show err
        Right x  -> return x

queryAlonzoEra :: Api.LocalNodeConnectInfo Api.CardanoMode -> Api.QueryInShelleyBasedEra Api.AlonzoEra a -> IO a
queryAlonzoEra info q = do
    e <- queryCardanoMode info $ Api.QueryInEra Api.AlonzoEraInCardanoMode
        $ Api.QueryInShelleyBasedEra Api.ShelleyBasedEraAlonzo q
    case e of
        Left err -> throwIO $ CardanoQueryException $ show err
        Right x  -> return x

queryBabbageEra :: Api.LocalNodeConnectInfo Api.CardanoMode -> Api.QueryInShelleyBasedEra Api.BabbageEra a -> IO a
queryBabbageEra info q = do
    e <- queryCardanoMode info $ Api.QueryInEra Api.BabbageEraInCardanoMode
        $ Api.QueryInShelleyBasedEra Api.ShelleyBasedEraBabbage q
    case e of
        Left err -> throwIO $ CardanoQueryException $ show err
        Right x  -> return x


queryUTxO :: GYEra -> Api.S.LocalNodeConnectInfo Api.S.CardanoMode -> Api.QueryUTxOFilter -> IO GYUTxOs
queryUTxO GYAlonzo  info q = fmap utxosFromApi $ queryAlonzoEra  info $ Api.QueryUTxO q
queryUTxO GYBabbage info q = fmap utxosFromApi $ queryBabbageEra info $ Api.QueryUTxO q

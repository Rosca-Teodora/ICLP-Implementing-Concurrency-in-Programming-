-- counter sincronizat tinut intr-un MVar de int => accesul la el va fi thread safe!

import Control.Concurrent 
import Control.Concurrent.MVar
import Control.Monad

takeprint :: MVar Int -> IO () 
takeprint stdo = do 
    msg <- takeMVar stdo 
    putStrLn msg 

increaseCounter :: MVar Int -> MVar Int()
increaseCounter cnt = cnt <- cnt + 1

main :: IO ()
main = do 
    stdo <- newEmptyMVar 
    cnt <- newMVar 0
    
    forkIO $ forever $ takeprint stdo 
    forkIO $ increaseCounter cnt 
    forkIO $ increaseCounter cnt 


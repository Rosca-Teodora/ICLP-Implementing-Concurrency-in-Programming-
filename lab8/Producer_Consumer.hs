-- producer consumer 
import Control.Concurrent 
import Control.Concurrent.MVar 
import Control.Monad 

-- functie pentru sincronizarea scrierii la STDOUT 
takeprint :: MVar String -> IO () 
takeprint stdo = do 
    msg <- takeMVar stdo 
    putStrLn msg 

producer :: MVar (Maybe Int) -> MVar String -> IO () 
producer buffer stdo = do 
    forM_ [1..5] $ \i -> do 
        putMVar stdo $ "Producer: " ++ show i 
        putMVar buffer (Just i) 

    putMVar buffer Nothing 

consumer :: MVar (Maybe Int) -> MVar String -> MVar () -> IO () 
consumer buffer stdo done = do 
    x <- takeMVar buffer 
    case x of 
        Nothing -> putMVar done () 
        Just v -> do 
            putMVar stdo $ "Consumed: " ++ show v 
            consumer buffer stdo done 

main :: IO ()
main = do 
    buffer <- newEmptyMVar 
    stdo <- newEmptyMVar 
    done <- newEmptyMVar 

    forkIO $ producer buffer stdo 
    forkIO $ consumer buffer stdo done 

    forkIO $ forever $ takeprint stdo 

    takeMVar done 
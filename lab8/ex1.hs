-- producer consumer 
import Control.Concurrent 
import Control.Concurrent.MVar 
import Control.Monad 

-- functie pentru sincronizarea scrierii la STDOUT 
takeprint :: MVar String -> IO () 
takeprint stdo = do 
    msg <- takeMVar stdo 
    putStrLn msg 

--producer :: MVar (Maybe Int) -> MVar String -> IO () 
producer ch stdo = do 
    forM_ [1..5] $ \i -> do 
        putMVar stdo $ "Producer: " ++ show i 
        mapM_ (WriteChan ch) (Just i) 

    mapM_ (writeChan ch) Nothing 


-- consumer :: MVar (Maybe Int) -> MVar String -> MVar () -> IO () 
consumer ch stdo done = do 
    x <- reacChan ch 
    case x of 
        Nothing -> mapM(writeChan ch) 
        Just v -> do 
            putMVar stdo $ "Consumed: " ++ show v 
            consumer buffer stdo done 

main :: IO ()
main = do 
    canal <- newChan
    stdo <- newEmptyMVar 
    done <- newEmptyMVar 

    forkIO $   

    forkIO $ forever $ takeprint stdo 

    takeMVar done 
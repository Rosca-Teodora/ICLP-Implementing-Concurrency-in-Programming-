-- implementam Reader-Writer 
-- permitem unui singur Writer la un moment de timp 
-- putem permite sa avem mai multi Readeri simultan 
-- implementam sincronizarea prin 2x mutex 

import Control.Concurrent 
import Control.Concurrent.MVar 
import Control.Monad 

takeprint :: MVar String -> IO () 
takeprint stdo = do 
    msg <- takeMVar stdo 
    putStrLn msg 

-- definim un tip de date algebric pentru Reader-Writer 
-- si apoi definim operatiile peste acest tip de date algebric 

data RW = RW 
    {
        sharedData :: MVar Int, 
        readerCount :: MVar Int, 
        readerMutex :: MVar (),
        writerMutex :: MVar (),
        stdo :: MVar String 
    }

enterRead :: RW -> IO ()
enterRead rw = do 
    takeMVar (readerMutex rw)                       -- acquire reader 
    n <- takeMVar (readerCount rw)
    when (n == 0) $ takeMVar (writerMutex rw)       -- acquire sharedData
    putMVar (readerCount rw) (n + 1)
    putMVar (readerMutex rw) ()                     -- release reader 

exitRead :: RW -> IO () 
exitRead rw = do 
    takeMVar (readerMutex rw)                       -- acquire reader 
    n <- takeMVar (readerCount rw)
    when (n == 1) $ putMVar (writerMutex rw) ()     -- release sharedData
    putMVar (readerCount rw) (n - 1)
    putMVar (readerMutex rw) ()                     -- release reader 

reader :: Int -> RW -> MVar () -> IO () 
reader id rw done = do 
    replicateM_ 5 $ do 
        enterRead rw 
        x <- readMVar (sharedData rw) 
        putMVar (stdo rw) $ "Reader " ++ show id ++ " reads " ++ show x 
        exitRead rw 

    putMVar done () 

writer :: RW -> MVar () -> IO () 
writer rw done = do 
    replicateM_ 5 $ do 
        takeMVar (writerMutex rw)           -- acquire sharedData
        x <- takeMVar (sharedData rw) 
        putMVar (sharedData rw) (x + 1)
        putMVar (stdo rw) $ "Writer writes " ++ show (x + 1)
        putMVar (writerMutex rw) ()         -- release sharedData 

    putMVar done ()

main :: IO ()
main = do 
    stdo <- newEmptyMVar 
    val <- newMVar 0 
    cnt <- newMVar 0 
    rm <- newMVar () 
    wm <- newMVar () 

    doneReaders <- newEmptyMVar 
    doneWriter <- newEmptyMVar

    let rw = RW val cnt rm wm stdo 

    forkIO $ writer rw doneWriter 

    forM_ [1..3] $ \i -> forkIO $ reader i rw doneReaders

    forkIO $ forever $ takeprint stdo 

    takeMVar doneWriter 
    replicateM_ 3 $ takeMVar doneReaders
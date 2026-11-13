-- scrieti un program concurent care lanseaza doua thread-uri 
-- thread-ul 1 afiseaza 'A'-uri
-- thread-ul 2 afiseaza 'B'-uri 
-- afisarea trebuie sa fie alternativa 
-- output: ABABABAB... 

-- scrierea la stdout nu este sincronizata 
-- o vom sincroniza manual, tot prin intermediul MVar-urilor 

-- pentru sincronizarea la STDOUT, vom folosi un MVar String 
-- in thread-ul principal, vom avea o actiune care ruleaza la infinit 
-- care asculta pe acel MVar String, afiseaza si elibereaza 

import Control.Concurrent 
import Control.Concurrent.MVar 
import Control.Monad 

takeprint :: MVar String -> IO () 
takeprint stdo = do 
    msg <- takeMVar stdo 
    putStrLn msg 

printA :: MVar () -> MVar () -> MVar String -> IO () 
printA turnA turnB stdo = 
    replicateM_ 10 $ do 
        takeMVar turnA 
        putMVar stdo "A"  -- pune in mvar si printeaza "A"
        putMVar turnB ()  -- elibereaza variabila B 

printB :: MVar () -> MVar () -> MVar String -> IO ()
printB turnA turnB stdo = do 
    replicateM_ 10 $ do 
        takeMVar turnB 
        putMVar stdo "B" 
        putMVar turnA () 

main :: IO () 
main = do 
    stdo <- newEmptyMVar 
    turnA <- newMVar () 
    turnB <- newEmptyMVar 

    forkIO $ forever $ takeprint stdo 
    forkIO $ printA turnA turnB stdo 

    printB turnA turnB stdo 


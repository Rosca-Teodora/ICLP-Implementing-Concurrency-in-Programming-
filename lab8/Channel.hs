import Control.Concurrent 
import Control.Monad 
import Data.Char 
{-
Canalele de comunicare - sunt utilizate pentru comunicarea intre thread-uri 
Ele sunt implementate tot prin MVar 

API de utilizare 
data Chan a 

newChan :: IO (Chan a)
writeChan :: Chan a -> a -> IO () -- nu este niciodata un apel blocant 
readChan :: Chan a -> IO a -- este blocant atunci cand canalul de comunicare
                           -- este vid 

canalele sunt in Control.Concurrent.Chan 

Exemplu. Avem doua canale, wordsIn si wordsOut 
Thread-ul principal citeste siruri pana intalaneste sirul "exit"
    si le pune in canalul wordsIn 
Un alt thread citeste din wordsIn, sparge sirurile in cuvinte,
    si pune cuvintele in wordsOut.
Un alt thread citeste cuvintele din wordsOut si le afiseaza 
    la STDOUT cu majuscule.

STDIN -> wordsIn -> wordsOut -> STDOUT 
    main       thread1     thread2 
-}

load wordsIn = forever $ do 
    str <- getLine 
    if str == "exit" then 
        return () 
    else do 
        writeChan wordsIn str 

move wordsIn wordsOut = do 
    str <- readChan wordsIn 
    let ls = words str 
    mapM_ (writeChan wordsOut) ls 

writeStdOut wordsOut = do 
    str <- readChan wordsOut 
    putStrLn $ map toUpper str 

main :: IO ()
main = do 
    wordsIn <- newChan 
    wordsOut <- newChan

    forkIO $ forever $ move wordsIn wordsOut 
    forkIO $ forever $ writeStdOut wordsOut 

    load wordsIn 


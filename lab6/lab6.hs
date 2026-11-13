import Control.Monad 

-- recapitulare pe monade si pe functii monadice 
-- replicateM_, mapM_, forM_ 

-- scriem monada pentru tipul de date algebric Maybe 

data MyMaybe a = MyNothing | MyJust a 
    deriving (Eq, Show)

instance Functor MyMaybe where 
    fmap _ MyNothing = MyNothing 
    fmap f (MyJust x) = MyJust $ f x 

instance Applicative MyMaybe where 
    pure x = MyJust x 

    MyNothing <*> _ = MyNothing 
    (MyJust f) <*> mx = fmap f mx 

-- mai clipiti din cand in cand ca sa stiu ca e ok si pot continua 
-- multumesc

instance Monad MyMaybe where 
    return = pure 

    MyNothing >>= _ = MyNothing 
    (MyJust x) >>= f = f x 

safeDiv :: Double -> Double -> MyMaybe Double 
safeDiv _ 0 = MyNothing 
safeDiv x y = MyJust (x / y) 

compute :: Double -> MyMaybe Double 
compute x = do 
    a <- MyJust x 
    b <- safeDiv a 0 
    safeDiv b 5 

safePos :: Int -> MyMaybe Int 
safePos x 
    | x > 0     = MyJust x 
    | otherwise = MyNothing 

test1 :: MyMaybe ()
test1 = mapM_ safePos [1, 2, 3]

test2 :: MyMaybe ()
test2 = mapM_ safePos [1, -2, 3]

test3 :: MyMaybe()
test3 = replicateM_ 3 (safePos 5)

-- replicateM_, forM_, forever, mapM_ 

-- implementam forM_ doar pentru liste 
forM_' :: Monad m => [a] -> (a -> m b) -> m ()
forM_' [] _ = pure () -- return ()
-- forM_' (x:xs) f = do 
--     f x 
--     forM_' xs f 
forM_' (x:xs) f = f x >> forM_' xs f 
-- m >>= \_ -> k   <=>   m >> k

mapM_' :: Monad m => (a -> m b) -> [a] -> m ()
mapM_' _ [] = return () 
mapM_' f (x:xs) =  do 
    f x 
    mapM_' f xs 

-- replicateM_' :: Applicative m => Int -> m a -> m () 
-- replicateM_' n action 
--     | n <= 0 = pure () 
--     | otherwise = action >> replicateM_' (n - 1) action 
replicateM_' :: Applicative m => Int -> m a -> m [a] 
replicateM_' n action 
    | n <= 0 = pure [] 
    | otherwise = pure (:) <*> action <*> replicateM_' (n - 1) action 

replicateMApplicative :: Applicative m => Int -> m a -> m () 
replicateMApplicative n action 
    | n <= 0 = pure () 
    | otherwise = pure (\_ _ -> ()) <*> action <*> replicateMApplicative (n - 1) action

replicateM_'' :: Monad m => Int -> m a -> m () 
replicateM_'' n action = forM_' [1..n] $ \_ -> action 

main :: IO () 
main = do 
    -- print ((+3) <$> (MyJust 5))
    -- print (MyJust (+3) <*> (MyJust 5))
    -- print $ compute 100 
    forM_' [1..5] $ \i -> do 
        print (i**i) 
        print i  

    replicateMApplicative 5 $ do 
        putStrLn "Invat Haskell"


-- Ex1: Scrieti mapM_, forM_ pentru tipuri care au Foldable drept clasa de tipuri (generalizare pt Liste de ex.)

-- Ex2: Definiti tipul de date algebric si scrieti instanta de foldable

data MyTree a = Nil | Leaf a | Tree (MyTree a)(MyTree a)
    deriving (Eq, Show)

-- Ex3: Aplicati functiile de la exercitiul 1 pe tipul de date de la exercitiul 2
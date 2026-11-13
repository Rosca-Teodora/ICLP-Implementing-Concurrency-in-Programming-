# Haskel

- Functor ```f<$>[a] = [f a]```  
- Applicative ```[f]<$>[a] = [f a]```

        a ---pure---> [a]
        ex: Maybe : 2 ---pure---> Just 2
                    2 ---pure---> [2]

- Monad = compunerea de functii din liceu 

        [f] compus cu [g] pastrand contextul 
        (>>=) :: [a] -> (a -> [b]) -> [b]
        ex:    Just -> ( Just -> String ) -> String 

        (>>) doar void  
        
OBS: Notatia [x] -> x se afla intr-o cutie (intr-un tip)


sigma type = sau x sau y
pi type = idfk 
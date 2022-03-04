{-@ LIQUID "--no-adt" @-}
{-@ LIQUID "--reflect" @-}
module SizedList where

import Prelude hiding(map, repeat, head, tail, reverse, length)
import Size

data List a = Cons a (List a) | Nil
{-@ measure emp @-}
emp Nil = True
emp _   = False

{-@ measure size :: List a -> Size @-}
-- inf: is defined for infinite depth.
{-@ measure inf  :: List a -> Bool @-}

{-@ type ListI a = {xs:List a| inf xs} @-}

-- ListG: list with size greater than S
{-@ type ListG a S = {xs:List a| size xs >= S || inf xs} @-}
-- ListS: list with size equal to S
{-@ type ListS a S = {xs:List a| size xs  = S} @-}
-- ListNE: non-empty list
{-@ type ListNE a  = {xs:List a| not (emp xs)} @-}

{-@ assume mkNil :: {n:_| n = Nil && inf n} @-}
mkNil :: List a
mkNil = Nil

{-@ assume mkICons :: forall <p::a -> Bool>
                   . a<p>
                  -> ListI a<p>
                  -> ListI a<p>
@-}
mkICons = Cons

{-@ assume mkCons :: forall <p::a -> Bool>
                   . i:Size
                  -> ({j:Size|j<i} -> a<p>)
                  -> ({j:Size|j<i} -> ListG a<p> j)
                  -> v:ListS a<p> i
@-}
mkCons :: Size -> (Size -> a) -> (Size -> List a) -> List a
mkCons i fx fxs | i >= 0    = let j = newSize i
                              in  Cons (fx j) (fxs j)
                | otherwise = undefined

{-@ assume out :: forall <p::a -> Bool>
                . j:Size
               -> {xs:ListNE a<p> | j < size xs || inf xs}
               -> (_, {v:ListS a<p> j |inf xs ==> inf v})
@-}
out :: Size -> List a -> (a, List a)
out _ Nil         = undefined
out _ (Cons x xs) = (x, xs)

{-@ head :: forall <p::a -> Bool>
          . j:Size
         -> {xs:ListNE a<p> | j < size xs || inf xs}
         -> a<p>
@-}
head :: Size -> List a -> a
head j = fst . out j

{-@ tail :: forall <p::a -> Bool>
          . j:Size
         -> {xs:ListNE a<p> | j < size xs || inf xs}
         -> {v:ListS a<p> j | inf xs ==> inf v}
@-}
tail :: Size -> List a -> List a
tail j xs = snd $ out j xs

{-@ headi :: forall <p::a->Bool>. {xs:ListNE a<p>|inf xs} -> a<p> @-}
headi = head 0

{-@ taili :: forall <p::a->Bool>. {xs:ListNE a<p>|inf xs}
                               -> ListI a<p> @-}
taili = tail 0

{-@ repeat :: i:Size -> _ -> ListS _ i @-}
repeat :: Size -> a -> List a
repeat i x = mkCons i (const x) $ \j -> repeat j x

{-@ map :: i:Size -> _ -> ListG _ i -> ListG _ i @-}
map :: Size -> (a -> b) -> List a -> List b
map i _ Nil = mkNil
map i f xs  = mkCons i (\j -> f $ head j xs) $ \j -> map j f (tail j xs)

{-@ append :: i:Size -> xs: ListG _ i -> ys: ListG _ i -> ListG _ i @-}
append i Nil ys  = ys
append i xs  ys  = mkCons i (\j -> head j xs)
                          $  \j -> append j (tail j xs) ys
module Eval where

import Data.Set
import Syntax

-- e[x<-s]
subst :: Expr -> Name -> Expr -> Expr
subst (Var y) x s
  | x == y = s
  | x /= y = Var y
subst (Lam y e) x s
  | x == y = Lam y e
  | x /= y && (y `notElem` fv s) = Lam y (subst (Lam y e) x s)
  | otherwise = let z = deduplication e s y in Lam z $ subst (subst e y (Var z)) x s
subst (App t1 t2) x s = App (subst t1 x s) (subst t2 x s)

-- α 変換のための関数: 変数の重複を防ぐ
deduplication :: Expr -> Expr -> Name -> Name
deduplication e1 e2 y
  | y' `elem` (fv e1 `union` fv e2) = deduplication e1 e2 y'
  | otherwise = y'
  where
    y' = y ++ "'"

-- 閉じた項か判定する
-- isRedex :: Expr -> Bool
-- isRedex e = Data.Set.null $ fv e

-- free variable の集合を求める
fv :: Expr -> Set Name
fv (Var x) = singleton x
fv (Lam x e) = fv e \\ singleton x
fv (App e1 e2) = fv e1 `union` fv e2

-- 1 ステップ評価関数
eval1 :: Expr -> Maybe Expr
eval1 (App (Lam x e) v)
  | val v = Just $ subst e x v
eval1 (App v e)
  | val v = do
    e' <- eval1 e
    return $ App v e'
eval1 (App e1 e2) = do
  e1' <- eval1 e1
  return $ App e1' e2
eval1 _ = Nothing

-- 評価関数
eval :: Expr -> Either Expr Expr
eval t = case eval1 t of
  Just s -> eval s
  Nothing
    | val t -> Right t -- value
  _ -> Left t -- stack term

ide :: Expr -> Expr
ide = App $ Lam "x" $ Var "x"

-- App (App (Lam "x" $ Var "x") (Var "x")) (App (Lam "y" $ Var "y") (Var "z"))
-- App (Lam "x" $ Var "y") (App (Lam "y" $ Var "y") (Var "z"))
-- ide (ide (Lam "z" $ ide $ Var "z"))
-- App (Lam "z" (Lam "y" $ Var "z")) (Lam "y" $ Var "z")

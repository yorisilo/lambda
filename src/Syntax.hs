module Syntax where

type Name = String

data Expr
  = Var Name
  | Lam Name Expr
  | App Expr Expr
  deriving (Eq, Show)

-- 値かどうか判定する
val :: Expr -> Bool
val (Lam _ _) = True
val _ = False

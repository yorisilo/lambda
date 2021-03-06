# lambda
create simple language (and processor)!!

cf.
- https://github.com/sdiehl/write-you-a-haskell
- [Introducing Haskell](https://www.cs.princeton.edu/~dpw/cos441-11/notes/slides15-lambda-proofs.pdf)
- [katatoshi/tapl](https://github.com/katatoshi/tapl)
- [つくってあそぼ ラムダ計算インタプリタ](https://speakerdeck.com/kmc_jp/implement-an-interpreter-of-lambda-calculus?slide=17)
- [lambda\.pdf](https://www.math.nagoya-u.ac.jp/~garrigue/lecture/2018_AW/lambda.pdf)
- TaPL

create an AST interpreter like the one below
```
ソースコード -字句解析-> トークン -構文解析-> AST -解釈実行-> 結果
```

## 2020-09-12 の流れ
- 2020-09-12 ゴールの確認: 型なしラムダ計算の evaluator を作る
- プログラミング言語ってどういうの想像します？
  - なんかすごいやつ
  - なんか作るの難しそう
- ラムダ計算みたいな単純なやつでも立派な言語です！これ(evaluator)作ります。
  - こんなおもちゃみたいに見える言語でもちゃんとチューリング完全！
- 今日はインタプリタを作るとはいってない
  - `ソースコード -字句解析-> トークン -構文解析-> AST -解釈実行-> 結果` という流れをすべてやるのがインタプリタとするなら、今日は AST を解釈して実行する部分 = evaluator を作成する。 evaluator はインタプリタの心臓部分なので一番大切！ parsing も大切だけどね！
  - 今日は人間パーサーとして振る舞ってもらう
  - 余談だが、よくおためしプログラミング言語を作るときに lisp とか scheme が採用されるのは、パーサーの部分の実装がメチャクチャ楽になるからである。実際作らなくてもイケたりする。なぜなら、 AST をそのまま書いていくのが lisp だからだ！！ アレは人間パーサーになることが求められる言語である。 lisp を書くときは機械みたいな人間になろう！
- はい、ではこんなラムダ計算の言語の処理系を作っていく

## 環境構築
for mac: asdf で入れた stack はうまく動かないので注意。 homebrew で stack を入れるのが楽

``` shell
# stack の設定
$ brew install stack
$ emacs .zshenv
if whence stack > /dev/null; then
  export PATH="$(stack path --local-bin):$PATH"
fi

if whence stack > /dev/null; then
  export PATH="$(stack path --compiler-bin):$PATH"
fi

# repository download
$ git clone https://github.com/yorisilo/lambda
$ cd lambda

# ghc とか入れる
$ stack setup

# build できるか確認
$ stack build

# ghc の repl 起動
# これを多用して色々コードを実行させていく
$ stack ghci
...
*Main Eval Lib Syntax> eval $ App (Lam "y" $ Var "z") (Lam "y" $ Var "z")
```

## 青写真
型なしラムダ計算ってこんなやつ。

- `(λx.x) y`
- `(λx.x) (λx.x)`
- `(λx.λy.λz.xy(xz))`

特徴
- チューリング完全なので、こいつだけで色々書ける。
- データはエンコーディングして使う。 cf. チャーチ数等
  - TODO: エンコーディングの具体例など追記する

cf.
- [ラムダ計算で代数的データ型を表現する方法 \- @syamino はてなダイアリー](https://syamino.hatenadiary.org/entry/20120524/p1)
- [代数的データ型をラムダ計算の中で表現する方法](https://www.slideshare.net/syamino/ss-12993070)
- [ラムダ計算での代数的データのエンコード的な話 \- Object\.create\(null\)](https://susisu.hatenablog.com/entry/2017/02/09/143358)

# untyped lambda calculus
## syntax

```
e ::=       (term)
    | x     (variable)
    | λx.e  (lambda abstraction)
    | e e   (function application)

v ::=       (value)
    | λx.e  (lambda abstraction)
```

## inference(reduction, evaluation) rules
small step の 操作的意味論で定義された call-by-value の評価規則

- call-by-value: まず外側の redex を簡約の候補にする。 そして、e2 が値に簡約されていれば、その redex を簡約する。
  e2 が値じゃない場合、先にそちらの簡約を行う。
  つまり、関数の引数から先に簡約するような評価規則。
  - redex: (λx.e1) e2 の形の項 = v e みたいな形の項のこと


```
------------------ (init)
        e

------------------ (beta)
λx.e v -> e[x<-v]

   e1 -> e1'
------------------ (app1)
e1 e2 -> e1' e2

   e2 -> e2'
------------------ (app2)
v1 e2 -> v1 e2'
```

ex.

```
id ::= λx.x
id (id (λz.id z)) -> id (λz.id z) -> λz.id z
```


exercice.

```
(λy.z) (λy.z) -> ???
```

<details>

```
(λy.z) (λy.z) -> z
```

</details>


### substitution
`e[x<-s]`: `e` に含まれる自由変数 `x` を `s` に置換する
  - ポイント: 置換によって項の `意味` を変えてはいけない

`s` は閉じた項 (自由変数の無い項) とする

substitution の定義

```
y[x<-s]      = if x == y then s else y
(λy.e)[x<-s] = if x == y              then λy.e
               if x /= y && y ∉ FV(s) then (λy.e[x<-s])
(t u)[x<-s]  = (t[x<-s]) (u[x<-s])
```

- `(λy.e)[x<-s]` に条件がない場合
  - `(λy.e)[x<-s] = (λy.e[x<-s])` 常に中に入って置換する

```
# だいたいうまくいく
(λy.x)[x<-(λz. z w)] = λy.λz. z w

# うまくいかない
(λx.x)[x<-y] =?= λx.y

# 本当はこうなってほしい
# x == y のときと x /= y のときで処理をわければうまくいく
(λx.x)[x<-y] = λx.x
```

- `(λy.e)[x<-s]` に `y ∉ FV(s)` という条件がない場合

```
# うまくいかない例
(λz.x)[x<-z] =?= λz.z

# 本当はこうなってほしい
# x /= y かつ z ∉ FV(z) という条件をつければうまくいく
(λz.x)[x<-z] = λz.x
```

ニュアンスとしては、 束縛変数と置換に使う変数は別のものであることを強調するために `y ∉ FV(s)` という条件が必要になってくるかんじ

これで、置換自体は soundness は満たすようになったが、完全ではなくなってしまったので、
`(λy.e)[x<-s]` の置換をしようとして `x == y` や `x /= y && y ∉ FV(s)` の条件を満たさない場合は、α 変換を適時用いて、`項の意味を変えず`に、変数名を変換することが必要になる。

TODO: どういう項のときにここを使用することになるのか具体的な項を書く

### α 変換
`λx.x` と `λy.y` は同じってことを表している規則

```
------------------
λx.e -> λy.e[x<-y]
```

### FV: 自由変数の集合

```
FV(x)      = {x}
FV (λx.e)  = FV (e) \ {x}
FV (e1 e2) = FV (e1) ∪ FV (e2)
```

#### 束縛変数と自由変数
- 束縛変数: lambda abstraction によって束縛されている変数
- 自由変数: 束縛変数ではない変数
以下の項における `x`, `y` が束縛変数、 `z` が自由変数である。

```
λx.λy.xyz
```

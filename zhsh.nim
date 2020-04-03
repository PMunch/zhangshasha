## This module is a port of the Java implementation of the Zhang-Shasha
## algorithm for tree edit distance (found here:
## https://github.com/ijkilchenko/ZhangShasha). It supports the simple
## string based language for creating trees that the original supports and
## allows the user to create their own trees for comparisson.
##
## It is also generic in nature, so the `label` of each `Node` could be any
## type as long as `==` is defined for it (and `$` if you want to print it).

import strutils
import sequtils

type
  Node*[T] = ref object
    ## Nodes contains the label used to describe the node,
    ## along with a sequence of child nodes
    label*: T
    index: int
    children*: seq[Node[T]]
    leftmost: Node[T]
  Tree*[T] = ref object
    ## The Tree type contains the root of a tree
    root*: Node[T]
    l: seq[int]
    keyroots: seq[int]
    labels: seq[T]
  Tokenizer* = object
    ## The Tokenizer is intended for parsing a simple tree syntax on the form:
    ## "f(a g(h))" where f is the root, a and g are children of f and h is a
    ## child of g
    tokens: seq[tuple[token: string, isSep: bool]]
    token: int

proc `$`*[T](node: Node[T]): string =
  ## Basic string operator to output a node. Outputs a similar format to what
  ## the tokenizer reads as input
  result = $node.label
  if node.children.len != 0:
    result = result & "("
    for child in node.children:
      result = result & $child & " "
    result = result & ")"

proc tokenize*(str: string): Tokenizer =
  ## Tokenize a string into a tokenizer for use in initializing a tree
  result.tokens = @[]
  for word in str.tokenize({'(',')',' '}):
    if word.isSep:
      if word.token.len > 1:
        for single in word.token:
          result.tokens.add((token: $single, isSep: true))
      else:
        result.tokens.add word
    else:
      result.tokens.add word

proc curToken(tokenizer: Tokenizer): tuple[token: string, isSep: bool] =
  tokenizer.tokens[tokenizer.token]

template doWhile(a, b: untyped): untyped =
  while true:
    b
    if not a:
      break

proc parseString(node: var Node[string], tokenizer: var Tokenizer): Node[string] =
  node.label = tokenizer.curToken.token
  tokenizer.token += 1
  if tokenizer.token >= tokenizer.tokens.len:
    return node
  if tokenizer.curToken.token == "(":
    tokenizer.token += 1
    doWhile tokenizer.curToken.token != ")":
      if tokenizer.curToken.token != " ":
        var newNode = new Node[string]
        newNode.children = @[]
        node.children.add(parseString(newNode, tokenizer))
      else:
        tokenizer.token += 1
    tokenizer.token += 1
  return node

proc initTree*(tokenizer: var Tokenizer): Tree[string] =
  result = Tree[string]()
  result.root = new Node[string]
  result.root.children = @[]
  result.root = parseString(result.root, tokenizer)
  if tokenizer.token != tokenizer.tokens.len:
    echo "Tokens not exhausted"
    quit 1

proc traverse[T](node: Node[T], labels: var seq[T]): seq[T] =
  for i in node.children:
    labels = traverse(i, labels)
  labels.add(node.label)
  return labels

proc traverse[T](tree: Tree[T]) =
  discard traverse(tree.root, tree.labels)

proc index[T](node: Node[T], idx: int): int =
  result = idx
  for i in node.children:
    result = index(i, result)
  result += 1
  node.index = result

proc index[T](tree: Tree[T]) =
  discard index(tree.root, 0)

proc leftmost[T](node: Node[T]) =
  if node == nil:
    return
  for i in node.children:
    leftmost(i)
  if node.children.len == 0:
    node.leftmost = node
  else:
    node.leftmost = node.children[0].leftmost

proc leftmost[T](tree: Tree[T]) =
  leftmost(tree.root)

proc getl[T](node: Node[T], l: var seq[int]): seq[int] =
  for i in node.children:
    l = getl(i, l)
  l.add(node.leftmost.index)
  return l

proc getl[T](tree: Tree[T]) =
  leftmost(tree)
  var tmpSeq = newSeq[int]()
  tree.l = getl(tree.root, tmpSeq)

proc getkeyroots[T](tree: Tree[T]) =
  for i in 0..<tree.l.len:
    var flag = 0
    for j in (i+1)..<tree.l.len:
      if tree.l[j] == tree.l[i]:
        flag = 1
    if flag == 0:
      tree.keyroots.add(i + 1)

proc zhangShasha*[T](tree1: Tree[T], tree2: Tree[T], delete = 1, insert = 1, relabel = 1): int =
  ## The main procedure to calculate the edit distance between two trees.
  ## Takes the two trees to compare along with three optional weights on what
  ## to consider as change.
  tree1.l = @[]
  tree1.keyroots = @[]
  tree1.labels = @[]
  tree2.l = @[]
  tree2.keyroots = @[]
  tree2.labels = @[]

  tree1.index()
  tree1.getl()
  tree1.getkeyroots()
  tree1.traverse()
  tree2.index()
  tree2.getl()
  tree2.getkeyroots()
  tree2.traverse()

  var td = newSeqWith(tree1.l.len + 1, newSeq[int](tree2.l.len + 1))

  proc treedist(l1, l2: seq[int], i, j: int, tree1, tree2: Tree[T]): int =
    var
      forestdist = newSeqWith(l1.len + 1, newSeq[int](l2.len + 1))

    forestdist[0][0] = 0
    for i1 in l1[i - 1]..i:
      forestdist[i1][0] = forestdist[i1 - 1][0] + delete
    for j1 in l2[j - 1]..j:
      forestdist[0][j1] = forestdist[0][j1 - 1] + insert
    for i1 in l1[i - 1]..i:
      for j1 in l2[j - 1]..j:
        let
          i_temp = if l1[i - 1] > i1 - 1: 0 else: i1 - 1
          j_temp = if l2[j - 1] > j1 - 1: 0 else: j1 - 1
        if l1[i1 - 1] == l1[i - 1] and l2[j1 - 1] == l2[j - 1]:
          let cost = if tree1.labels[i1 - 1] == tree2.labels[j1 - 1]: 0 else: relabel
          forestdist[i1][j1] = min(
            min(forestdist[i_temp][j1] + delete, forestdist[i1][j_temp] + insert),
            forestdist[i_temp][j_temp] + cost)
          td[i1][j1] = forestdist[i1][j1]
        else:
          let
            i1_temp = l1[i1 - 1] - 1
            j1_temp = l2[j1 - 1] - 1
            i_temp2 = if l1[i - 1] > i1_temp: 0 else: i1_temp
            j_temp2 = if l2[j - 1] > j1_temp: 0 else: j1_temp
          forestdist[i1][j1] = min(
            min(forestdist[i_temp][j1] + delete, forestdist[i1][j_temp] + insert),
            forestdist[i_temp2][j_temp2] + td[i1][j1])
    return forestdist[i][j]

  for i in 1..tree1.keyroots.len:
    for j in 1..tree2.keyroots.len:
      var
        r1 = tree1.keyroots[i-1]
        r2 = tree2.keyroots[j-1]
      td[r1][r2] = treedist(tree1.l, tree2.l, r1, r2, tree1, tree2)

  return td[tree1.l.len][tree2.l.len]

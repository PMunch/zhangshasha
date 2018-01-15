import zhsh
var
  test1 = "d"
  tokenizer1 = test1.tokenize()
  test2 = "g(h)"
  tokenizer2 = test2.tokenize()
  t1 = initTree(tokenizer1)
  t2 = initTree(tokenizer2)
  t3 = Tree(root:
    Node(label: "g", children: @[
      Node(label: "h", children: @[])
    ])
  )
echo "Edit distance between the two trees is " & $zhangShasha(t1, t3)
echo "Edit distance between the two trees is " & $zhangShasha(t2, t3)


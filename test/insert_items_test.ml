(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let base_fs =
  let open Tree in
  from_cwd
    [ dir
        ~metadata:(Some 0)
        ~name:"a"
        [ dir
            ~name:"a1"
            [ file ~name:"article-a1-1.md" "0"
            ; file ~name:"article-a1-2.md" "1"
            ; file ~name:"article-a1-3.md" "1"
            ; file ~name:"article-a1-3.md.rej" "1"
            ]
        ; dir
            ~name:"a2"
            [ file ~name:"article-a2-1.md" "3"
            ; file ~name:"article-a2-2.md" "4"
            ]
        ; dir
            ~name:"a3"
            [ dir
                ~name:"foo"
                [ file ~name:"foobar.md" "Hello World"
                ; file ~name:"bar.md" "Hello World from A"
                ]
            ]
        ]
    ; dir
        ~name:"b"
        [ dir ~name:"b1" [ file ~name:"article-b1-1.md" "b1" ]
        ; dir ~name:"b2" [ file ~name:"article-b2-1.md" "b2" ]
        ; dir ~name:"b3" []
        ; dir ~name:"b4" [ file ~name:"article-b4-1.md" "b4" ]
        ]
    ; dir
        ~name:"c"
        [ dir ~name:"c1" []
        ; dir ~name:"c2" []
        ; dir ~name:"c3" []
        ; dir ~name:"c4" []
        ]
    ]
;;

let%expect_test "insert empty list" =
  base_fs |> Tree.insert_items [] |> Tree.tree |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "insert a list" =
  base_fs
  |> Tree.insert_items
       Item.[ file ~name:"foo" ""; file ~name:"bar" ""; file ~name:"foobar" "" ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
      └─bar
      └─foo
      └─foobar
    |}]
;;

let%expect_test "insert a list" =
  base_fs
  |> Tree.insert_items
       ~scope:(Path.rel [ "c"; "c2"; "a-new"; "folder" ])
       Item.[ file ~name:"foo" ""; file ~name:"bar" ""; file ~name:"foobar" "" ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
          └─a-new/
            └─folder/
              └─bar
              └─foo
              └─foobar
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "insert a list" =
  base_fs
  |> Tree.insert_items
       ~scope:(Path.rel [ "a-new"; "folder" ])
       Item.[ file ~name:"foo" ""; file ~name:"bar" ""; file ~name:"foobar" "" ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─a-new/
        └─folder/
          └─bar
          └─foo
          └─foobar
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "insert a list with a conflict" =
  base_fs
  |> Tree.insert_items
       ~scope:(Path.rel [ "a"; "a1" ])
       Item.
         [ file ~name:"foo" ""
         ; file ~name:"bar" ""
         ; file ~name:"article-a1-2.md" ""
         ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-2.md.rej
          └─article-a1-3.md
          └─article-a1-3.md.rej
          └─bar
          └─foo
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "insert a list with a conflict with a loop" =
  base_fs
  |> Tree.insert_items
       ~scope:(Path.rel [ "a"; "a1" ])
       ~on_conflict:(Conflict.rename_current Fun.id)
       Item.
         [ file ~name:"foo" ""
         ; file ~name:"bar" ""
         ; file ~name:"article-a1-2.md" ""
         ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
          └─bar
          └─foo
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "insert a list with a conflict with a loop and an other giveup" =
  base_fs
  |> Tree.insert_items
       ~scope:(Path.rel [ "a"; "a1" ])
       ~on_conflict:(Conflict.rename_current Fun.id)
       ~give_up:(Conflict.retain `Neither)
       Item.
         [ file ~name:"foo" ""
         ; file ~name:"bar" ""
         ; file ~name:"article-a1-2.md" ""
         ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
          └─bar
          └─foo
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "insert a list with a conflict and a collision" =
  base_fs
  |> Tree.insert_items
       ~scope:(Path.rel [ "a"; "a1" ])
       ~give_up:(Conflict.retain `Neither)
       Item.
         [ file ~name:"foo" ""
         ; file ~name:"bar" ""
         ; file ~name:"article-a1-3.md" ""
         ]
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
          └─article-a1-3.md
          └─article-a1-3.md.rej
          └─article-a1-3.md.rej.rej
          └─bar
          └─foo
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
        └─a3/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

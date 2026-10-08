(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let insert_items ?scope ?on_metadata ?on_conflict ?give_up items fs =
  Tree.insert_items
    ?scope
    ?on_metadata
    ?on_conflict
    ?give_up
    Tree.Simple.equal_item
    items
    fs
;;

let merge ?on_metadata ?on_conflict ?give_up items fs =
  Tree.merge ?on_metadata ?on_conflict ?give_up Tree.Simple.equal_item items fs
;;

let empty_fs : Tree.Simple.t = Tree.from_cwd []

let simple_fs : Tree.Simple.t =
  let open Tree in
  from_cwd
    [ dir
        ~name:"folder-1"
        [ dir ~name:"folder-a" []
        ; dir ~name:"folder-b" []
        ; dir ~name:"folder-c" []
        ; dir ~name:"folder-d" []
        ; dir ~name:"folder-e" []
        ; dir ~name:"folder-f" []
        ]
    ; dir
        ~name:"folder-2"
        [ dir ~name:"folder-a" []
        ; dir ~name:"folder-b" [ file ~name:"message.txt" "hello world" ]
        ; dir ~name:"folder-c" []
        ]
    ; dir ~name:"folder-3" []
    ]
;;

let%expect_test
    "insertion of an empty list from an empty folder from the root should \
     produce the same file system"
  =
  let computed_fs = empty_fs |> insert_items [] in
  Test_util.dump_bool (Tree.Simple.equal empty_fs computed_fs);
  [%expect {| true |}]
;;

let%expect_test
    "insertion of an empty list from a filled folder from the root should \
     produce the same file system"
  =
  let computed_fs = simple_fs |> insert_items [] in
  Test_util.dump_bool (Tree.Simple.equal simple_fs computed_fs);
  [%expect {| true |}]
;;

let%expect_test
    "insertion of an empty list from an empty folder from the a specific scope \
     should introduce the given scope as a children of the filesystem"
  =
  empty_fs
  |> insert_items ~scope:(Path.rel [ "foo"; "bar" ]) []
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─foo/
        └─bar/
    |}]
;;

let%expect_test
    "insertion of an empty list from a folder from the a specific scope should \
     introduce the given scope as a children of the filesystem"
  =
  simple_fs
  |> insert_items ~scope:(Path.rel [ "foo"; "bar" ]) []
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─folder-1/
        └─folder-a/
        └─folder-b/
        └─folder-c/
        └─folder-d/
        └─folder-e/
        └─folder-f/
      └─folder-2/
        └─folder-a/
        └─folder-b/
          └─message.txt
        └─folder-c/
      └─folder-3/
      └─foo/
        └─bar/
    |}]
;;

let%expect_test
    "insertion the same filesystem should produce the same filesystem"
  =
  let computed_fs = empty_fs |> merge empty_fs in
  Test_util.dump_bool (Tree.Simple.equal empty_fs computed_fs);
  [%expect {| true |}]
;;

let%expect_test
    "insertion the same filesystem should produce the same filesystem"
  =
  let computed_fs = simple_fs |> merge simple_fs in
  Test_util.dump_bool (Tree.Simple.equal simple_fs computed_fs);
  [%expect {| true |}]
;;

let%expect_test "Do not trigger conflict when file are identical" =
  let computed_fs =
    simple_fs
    |> insert_items
         Tree.
           [ dir
               ~name:"folder-2"
               [ dir ~name:"folder-b" [ file ~name:"message.txt" "hello world" ]
               ]
           ]
  in
  Test_util.dump_bool (Tree.Simple.equal simple_fs computed_fs);
  [%expect {| true |}]
;;

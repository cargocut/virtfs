(* Copyright (c) 2026, Cargocut and the Virtfs developpers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let%expect_test "move" =
  let open Path in
  let source = rel [ "foo"; "bar"; "index.html" ]
  and into = abs [ "hello"; "world" ] in
  move ~into source |> dump_path;
  [%expect {| /hello/world/index.html |}]
;;

let%expect_test "move (make sense because it is resolved to `foo`)" =
  let open Path in
  let source = rel [ "foo"; "bar"; ".." ]
  and into = abs [ "hello"; "world" ] in
  move ~into source |> dump_path;
  [%expect {| /hello/world/foo |}]
;;

let%expect_test "rename" =
  let open Path in
  let source = rel [ "foo"; "bar"; "index.tpl.html" ]
  and new_name = "renamed-document" in
  rename ~new_name source |> dump_path;
  [%expect {| ./foo/bar/renamed-document |}]
;;

let%expect_test "rename with extension preservation" =
  let open Path in
  let source = rel [ "foo"; "bar"; "index.tpl.html" ]
  and new_name = "renamed-document" in
  rename ~preserve_extension:`Ext ~new_name source |> dump_path;
  [%expect {| ./foo/bar/renamed-document.html |}]
;;

let%expect_test "rename with extension preservation" =
  let open Path in
  let source = rel [ "foo"; "bar"; "index.tpl.html" ]
  and new_name = "renamed-document" in
  rename ~preserve_extension:`Compound ~new_name source |> dump_path;
  [%expect {| ./foo/bar/renamed-document.tpl.html |}]
;;

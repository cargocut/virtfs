(* Copyright (c) 2026, Cargocut and the Virtfs developers.
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

let%expect_test "relocate with different path kind" =
  let open Path in
  let into = Path.abs [ "foo"; "bar" ]
  and source = Path.rel [ "foo"; "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| /foo/bar/foo/bar/index.md |}]
;;

let%expect_test "relocate with different path kind" =
  let open Path in
  let into = Path.rel [ "foo"; "bar" ]
  and source = Path.abs [ "foo"; "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/foo/bar/index.md |}]
;;

let%expect_test "relocate with same path kind" =
  let open Path in
  let into = Path.abs [ "foo"; "bar" ]
  and source = Path.abs [ "foo"; "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| /foo/bar/index.md |}]
;;

let%expect_test "relocate with same path kind" =
  let open Path in
  let into = Path.rel [ "foo"; "bar" ]
  and source = Path.rel [ "foo"; "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/index.md |}]
;;

let%expect_test "relocate with same path kind" =
  let open Path in
  let into = Path.rel [ "foo"; "bar" ]
  and source = Path.rel [ "foo"; "bar"; ".."; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/index.md |}]
;;

let%expect_test "Force relocation" =
  let open Path in
  let into = Path.abs [ "foo"; "bar" ]
  and source = Path.abs [ "foo"; "bar"; "index.md" ] in
  relocate ~strategy:`Force ~into source |> dump_path;
  [%expect {| /foo/bar/foo/bar/index.md |}]
;;

let%expect_test "Inject relocation" =
  let open Path in
  let into = Path.rel [ "foo"; "bar" ]
  and source = Path.rel [ "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/index.md |}]
;;

let%expect_test "Inject relocation" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "baz" ]
  and source = Path.rel [ "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/index.md |}]
;;

let%expect_test "Inject relocation" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "baz"; "foobar"; "a"; "b"; "c" ]
  and source = Path.rel [ "foobar"; "a"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/baz/foobar/a/index.md |}]
;;

let%expect_test "Inject relocation" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "baz"; "foobar"; "a"; "b"; "c" ]
  and source = Path.rel [ "d"; "a"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/baz/foobar/a/b/c/d/a/index.md |}]
;;

let%expect_test "Inject relocation" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "baz" ]
  and source = Path.rel [ "bar"; "foobar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/foobar/index.md |}]
;;

let%expect_test "Inject relocation" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "baz" ]
  and source = Path.rel [ "bar"; "index.md" ] in
  relocate ~into source |> dump_path;
  [%expect {| ./foo/bar/index.md |}]
;;

let%expect_test "relocate with different path kind (with ignore)" =
  let open Path in
  let into = Path.rel [ "foo"; "bar" ]
  and source = Path.abs [ "foo"; "bar"; "index.md" ] in
  relocate ~ignore_kind:true ~into source |> dump_path;
  [%expect {| ./foo/bar/index.md |}]
;;

let%expect_test "relocate with different path kind (with ignore)" =
  let open Path in
  let into = Path.rel [ "foo"; "bar" ]
  and source = Path.abs [ "foo"; "bar"; ".."; "index.md" ] in
  relocate ~ignore_kind:true ~into source |> dump_path;
  [%expect {| ./foo/index.md |}]
;;

let%expect_test "relocate with resolution" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "test" ]
  and source = Path.rel [ ".."; ".."; "index.md" ] in
  relocate ~ignore_kind:true ~into source |> dump_path;
  [%expect {| ./foo/index.md |}]
;;

let%expect_test "relocate with resolution - 2" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "test" ]
  and source = Path.rel [ ".."; ".."; ".."; "index.md" ] in
  relocate ~ignore_kind:true ~into source |> dump_path;
  [%expect {| ./index.md |}]
;;

let%expect_test "relocate with resolution - 3" =
  let open Path in
  let into = Path.rel [ "foo"; "bar"; "test" ]
  and source = Path.rel [ ".."; ".."; ".."; ".."; "index.md" ] in
  relocate ~ignore_kind:true ~into source |> dump_path;
  [%expect {| ./../index.md |}]
;;

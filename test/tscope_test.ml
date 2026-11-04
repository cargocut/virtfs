(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let%expect_test "tscope check - standard case" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - standard case 2" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - is the scope" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar is unscoped by scope: ./foo/bar |}]

let%expect_test "tscope check - outside of the scope" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo is unscoped by scope: ./foo/bar |}]

let%expect_test "tscope check - cheat with traversal" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path =
    let open Tpath in
    from (v (Path.rel [ "foo"; "bar"; "baz" ])) [ ".."; ".."; ".." ]
  in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| . is unscoped by scope: ./foo/bar |}]

let%expect_test "tscope check - outside of the scope with absolute path" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.abs [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| /foo/bar/baz is unscoped by scope: ./foo/bar |}]

let%expect_test "tscope check - sibling sharing a name prefix" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "barbaz"; "qux" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/barbaz/qux is unscoped by scope: ./foo/bar |}]

let%expect_test "tscope check - traversal staying inside the scope" =
  let exclusions = []
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path =
    let open Tpath in
    from (v (Path.rel [ "foo"; "bar"; "baz" ])) [ ".."; "qux" ]
  in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - exclusion not involved" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - path is an exclusion" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "excluded" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/excluded overlap with: ./foo/bar/excluded |}]

let%expect_test "tscope check - path is inside an exclusion" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "excluded"; "a"; "b" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/excluded/a/b overlap with: ./foo/bar/excluded |}]

let%expect_test "tscope check - path is a parent of an exclusion" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "baz"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/baz overlap with: ./foo/bar/baz/excluded |}]

let%expect_test "tscope check - sibling of an exclusion sharing a name prefix" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "excluded_too" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - multiple exclusions, match the last one" =
  let exclusions =
    [
      Path.rel [ "foo"; "bar"; "a" ]
    ; Path.rel [ "foo"; "bar"; "b" ]
    ; Path.rel [ "foo"; "bar"; "c" ]
    ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "c"; "d" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/c/d overlap with: ./foo/bar/c |}]

let%expect_test "tscope check - multiple nested exclusions, first match wins" =
  let exclusions =
    [ Path.rel [ "foo"; "bar"; "a"; "b" ]; Path.rel [ "foo"; "bar"; "a" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "a"; "b"; "c" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/a/b/c overlap with: ./foo/bar/a/b |}]

let%expect_test "tscope check - unscoped takes precedence over exclusions" =
  let exclusions = [ Path.rel [ "foo" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/baz is unscoped by scope: ./foo/bar |}]

let%expect_test "tscope check - exclusion covering the whole scope" =
  let exclusions = [ Path.rel [ "foo" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/baz overlap with: ./foo |}]

let%expect_test "tscope check - exclusion outside of the scope" =
  let exclusions = [ Path.rel [ "elsewhere" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "baz" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - absolute exclusion does not match relative path"
    =
  let exclusions = [ Path.abs [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "excluded" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - traversal sneaking into an exclusion" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path =
    let open Tpath in
    from (v (Path.rel [ "foo"; "bar"; "baz" ])) [ ".."; "excluded"; "x" ]
  in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/excluded/x overlap with: ./foo/bar/excluded |}]

let%expect_test "tscope check - traversal escaping an exclusion" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path =
    let open Tpath in
    from (v (Path.rel [ "foo"; "bar"; "excluded"; "x" ])) [ ".."; ".."; "baz" ]
  in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check

let%expect_test "tscope check - non-normalized exclusion" =
  let exclusions = [ Path.rel [ "foo"; "bar"; "baz"; ".."; "excluded" ] ]
  and scope_path = Tpath.v (Path.rel [ "foo"; "bar" ])
  and path = Tpath.v (Path.rel [ "foo"; "bar"; "excluded"; "x" ]) in
  let scope = Tscope.make ~exclusions scope_path in
  path |> Tscope.check ~scope |> dump_tscope_check;
  [%expect {| ./foo/bar/excluded/x overlap with: ./foo/bar/excluded |}]

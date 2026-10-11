(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let dump = dump_option Path.to_string

let%expect_test "dump some scoping path" =
  let open Path in
  [ scope_under ~strict:false ~parent:cwd cwd
  ; scope_under ~parent:cwd (rel [ "foo"; "bar"; "baz" ])
  ; scope_under cwd ~parent:(rel [ "foo"; "bar"; "baz" ])
  ; scope_under ~parent:(rel [ "foo"; "bar"; "baz" ]) (rel [ "bar"; "baz" ])
  ; scope_under
      ~parent:(rel [ "foo"; "bar"; "baz" ])
      (rel [ "foo"; "bar"; "baz"; "foobar" ])
  ; scope_under
      ~parent:(rel [ "foo"; "bar" ])
      (rel [ "foo"; "bar"; "baz"; ".." ])
  ; scope_under
      ~parent:(rel [ "foo"; "bar"; "foobar" ])
      (rel [ "foo"; "bar"; "baz"; ".."; "foobar" ])
  ; scope_under
      ~parent:(rel [ "foo"; "bar"; "foobar" ])
      (rel
         [ "foo"; "bar"; "baz"; ".."; "foobar"; ".."; "foobar"; "a"; "b"; "c" ])
  ; scope_under
      ~parent:(abs [ "foo"; "bar"; "foobar" ])
      (abs
         [ "foo"; "bar"; "baz"; ".."; "foobar"; ".."; "foobar"; "a"; "b"; "c" ])
  ; scope_under ~parent:(rel [ "foo"; "bar"; "baz" ]) (rel [ "a"; "b"; "c" ])
  ; scope_under ~strict:true ~parent:cwd cwd
  ; scope_under ~strict:false ~parent:cwd root
  ]
  |> List.iter dump;
  [%expect
    {|
    Some (./)
    Some (./foo/bar/baz)
    None
    None
    Some (./foobar)
    Some (./)
    Some (./)
    Some (./a/b/c)
    Some (./a/b/c)
    None
    None
    None
    |}]
;;

let%expect_test "resolve under scoping" =
  let open Path in
  [ scope_under
      ~parent:(rel [ "foo"; "bar"; "foobar" ])
      (rel
         [ "foo"; "bar"; "baz"; ".."; "foobar"; ".."; "foobar"; "a"; "b"; "c" ])
    |> Option.map (resolve ~from:(rel [ "foo"; "bar"; "foobar" ]))
  ; scope_under
      ~parent:(abs [ "foo"; "bar"; "foobar" ])
      (abs
         [ "foo"; "bar"; "baz"; ".."; "foobar"; ".."; "foobar"; "a"; "b"; "c" ])
    |> Option.map (resolve ~from:(abs [ "foo"; "bar"; "foobar" ]))
  ]
  |> List.iter dump;
  [%expect {|
    Some (./foo/bar/foobar/a/b/c)
    Some (/foo/bar/foobar/a/b/c)
    |}]
;;

(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let%expect_test "dump a Tpath" =
  let open Path in
  let open Tpath in
  [
    from (v (rel [])) [ "bar"; "baz" ]
  ; from (v (rel [ "foo"; "bar" ])) [ "bar"; "baz" ]
  ; from (v (rel [ "foo"; "bar" ])) [ ".."; "baz" ]
  ; from (v (rel [ "foo"; "bar" ])) [ ".."; ".."; "foo" ]
  ]
  |> List.iter dump_tpath;
  [%expect
    {|
    [v][ ][ ]./bar/baz
    [v][ ][ ]./foo/bar/bar/baz
    [v][ ][ ]./foo/baz
    [v][ ][ ]./foo
    |}]

let%expect_test "dump a Tpath" =
  let open Path in
  let open Tpath in
  [
    from (c ~readable:Tbool.yes ~writable:Tbool.no (rel [])) [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.yes ~writable:Tbool.no (rel [ "foo"; "bar" ]))
      [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.yes ~writable:Tbool.no (rel [ "foo"; "bar" ]))
      [ ".."; "baz" ]
  ; from
      (c ~readable:Tbool.yes ~writable:Tbool.no (rel [ "foo"; "bar" ]))
      [ ".."; ".."; "foo" ]
  ]
  |> List.iter dump_tpath;
  [%expect
    {|
    [x][x][ ]./bar/baz
    [x][x][ ]./foo/bar/bar/baz
    [x][x][ ]./foo/baz
    [x][x][ ]./foo
    |}]

let%expect_test "dump a Tpath" =
  let open Path in
  let open Tpath in
  [
    from (c ~readable:Tbool.no ~writable:Tbool.no (rel [])) [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.no ~writable:Tbool.no (rel [ "foo"; "bar" ]))
      [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.no ~writable:Tbool.no (rel [ "foo"; "bar" ]))
      [ ".."; "baz" ]
  ; from
      (c ~readable:Tbool.no ~writable:Tbool.no (rel [ "foo"; "bar" ]))
      [ ".."; ".."; "foo" ]
  ]
  |> List.iter dump_tpath;
  [%expect
    {|
    [x][ ][ ]./bar/baz
    [x][ ][ ]./foo/bar/bar/baz
    [x][ ][ ]./foo/baz
    [x][ ][ ]./foo
    |}]

let%expect_test "dump a Tpath" =
  let open Path in
  let open Tpath in
  [
    from (c ~readable:Tbool.no ~writable:Tbool.yes (rel [])) [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.no ~writable:Tbool.yes (rel [ "foo"; "bar" ]))
      [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.no ~writable:Tbool.yes (rel [ "foo"; "bar" ]))
      [ ".."; "baz" ]
  ; from
      (c ~readable:Tbool.no ~writable:Tbool.yes (rel [ "foo"; "bar" ]))
      [ ".."; ".."; "foo" ]
  ]
  |> List.iter dump_tpath;
  [%expect
    {|
    [x][ ][x]./bar/baz
    [x][ ][x]./foo/bar/bar/baz
    [x][ ][x]./foo/baz
    [x][ ][x]./foo
    |}]

let%expect_test "dump a Tpath" =
  let open Path in
  let open Tpath in
  [
    from (c ~readable:Tbool.yes ~writable:Tbool.yes (rel [])) [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.yes ~writable:Tbool.yes (rel [ "foo"; "bar" ]))
      [ "bar"; "baz" ]
  ; from
      (c ~readable:Tbool.yes ~writable:Tbool.yes (rel [ "foo"; "bar" ]))
      [ ".."; "baz" ]
  ; from
      (c ~readable:Tbool.yes ~writable:Tbool.yes (rel [ "foo"; "bar" ]))
      [ ".."; ".."; "foo" ]
  ]
  |> List.iter dump_tpath;
  [%expect
    {|
    [x][x][x]./bar/baz
    [x][x][x]./foo/bar/bar/baz
    [x][x][x]./foo/baz
    [x][x][x]./foo
    |}]

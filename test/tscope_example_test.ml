(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(* Real-world usage of [Tscope], modelled after the [Workspace] of GPBE: a
   project is split into a [source] (read-only), a [target] (write-only, the
   generated site, relocated according to the server root), a [cache]
   (read/write) and a [server] (virtual, used to compute URLs). Each concrete
   component has a scope that excludes the other components nested in it. *)

open Test_util

module Workspace = struct
  type source = (Tbool.yes, Tbool.no) Tpath.c
  type target = (Tbool.no, Tbool.yes) Tpath.c
  type cache = (Tbool.yes, Tbool.yes) Tpath.c

  type t = {
      source : source
    ; target : target
    ; cache : cache
    ; server : Tpath.v
    ; source_scope : (Tbool.yes, Tbool.yes, Tbool.no) Tscope.t
    ; target_scope : (Tbool.yes, Tbool.no, Tbool.yes) Tscope.t
    ; cache_scope : (Tbool.yes, Tbool.yes, Tbool.yes) Tscope.t
  }

  (* Like in GPBE, an exclusion is only kept if it is (strictly) nested in the
     scope. Otherwise (for example, when the cache is stored in the target), it
     would exclude the whole scope. *)
  let make_scope ~exclusions path =
    let parent = Tpath.path path in
    let exclusions =
      List.filter (Path.is_scoped_by ~strict:true ~parent) exclusions
    in
    Tscope.make ~exclusions path

  let make ?(server_root = []) ?(source = Path.cwd)
      ?(target = Path.rel [ "_site" ])
      ?(cache = fun ~target:_ -> Path.rel [ "_cache" ]) () =
    let server = Path.abs server_root in
    (* The target is grafted with the server root so that the generated site is
       served at the right URL (see
       https://yocaml.github.io/tutorial/path-resolver.html). *)
    let target = Path.graft ~ignore_kind:true ~into:target server in
    let cache = cache ~target in
    let source = Tpath.c ~readable:Tbool.yes ~writable:Tbool.no source
    and target = Tpath.c ~readable:Tbool.no ~writable:Tbool.yes target
    and cache = Tpath.c ~readable:Tbool.yes ~writable:Tbool.yes cache
    and server = Tpath.v server in
    let tp = Tpath.path target and cp = Tpath.path cache in
    {
      source
    ; target
    ; cache
    ; server
    ; source_scope = make_scope ~exclusions:[ tp; cp ] source
    ; target_scope = make_scope ~exclusions:[ cp ] target
    ; cache_scope = make_scope ~exclusions:[ tp ] cache
    }

  let from_source ws xs = Tpath.from ws.source xs
  let from_target ws xs = Tpath.from ws.target xs
  let from_cache ws xs = Tpath.from ws.cache xs
end

let check ~scope path =
  match Tscope.check ~scope path with
  | Ok () -> print_endline (Path.to_filename (Tpath.path path) ^ " is ok")
  | result -> dump_tscope_check result

let dump_workspace ws =
  let open Workspace in
  dump_tpath ws.source;
  dump_tpath ws.target;
  dump_tpath ws.cache;
  dump_tpath ws.server

(* {1 Default workspace} *)

let%expect_test "default workspace layout" =
  Workspace.make () |> dump_workspace;
  [%expect
    {|
    [x][x][ ].
    [x][ ][x]./_site
    [x][x][x]./_cache
    [v][ ][ ]
    |}]

let%expect_test "source - reading articles and pages" =
  let ws = Workspace.make () in
  let scope = ws.source_scope in
  Workspace.from_source ws [ "articles"; "first-article.md" ] |> check ~scope;
  Workspace.from_source ws [ "pages"; "index.md" ] |> check ~scope;
  Workspace.from_source ws [ "articles" ] |> check ~scope;
  [%expect
    {|
    ./articles/first-article.md is ok
    ./pages/index.md is ok
    ./articles is ok
    |}]

let%expect_test "source - the target and the cache are not part of the source" =
  let ws = Workspace.make () in
  let scope = ws.source_scope in
  Workspace.from_source ws [ "_site"; "index.html" ] |> check ~scope;
  Workspace.from_source ws [ "_cache"; "deps" ] |> check ~scope;
  Workspace.from_source ws [ "_site" ] |> check ~scope;
  [%expect
    {|
    ./_site/index.html overlap with: ./_site
    ./_cache/deps overlap with: ./_cache
    ./_site overlap with: ./_site
    |}]

let%expect_test "source - a file sharing a prefix with the target is legit" =
  let ws = Workspace.make () in
  let scope = ws.source_scope in
  Workspace.from_source ws [ "_site.ml" ] |> check ~scope;
  Workspace.from_source ws [ "_sites"; "index.md" ] |> check ~scope;
  [%expect {|
    ./_site.ml is ok
    ./_sites/index.md is ok
    |}]

let%expect_test "target - writing generated pages" =
  let ws = Workspace.make () in
  let scope = ws.target_scope in
  Workspace.from_target ws [ "index.html" ] |> check ~scope;
  Workspace.from_target ws [ "articles"; "first-article.html" ] |> check ~scope;
  Workspace.from_target ws [ "css"; "style.css" ] |> check ~scope;
  [%expect
    {|
    ./_site/index.html is ok
    ./_site/articles/first-article.html is ok
    ./_site/css/style.css is ok
    |}]

let%expect_test "target - the target root itself cannot be erased" =
  let ws = Workspace.make () in
  let scope = ws.target_scope in
  Workspace.from_target ws [] |> check ~scope;
  Workspace.from_target ws [ "." ] |> check ~scope;
  [%expect
    {|
    ./_site is unscoped by scope: ./_site
    ./_site is unscoped by scope: ./_site
    |}]

let%expect_test "target - a write cannot leak into the source" =
  let ws = Workspace.make () in
  let scope = ws.target_scope in
  Workspace.from_target ws [ ".."; "articles"; "first-article.md" ]
  |> check ~scope;
  Workspace.from_target ws [ ".."; ".."; "etc"; "passwd" ] |> check ~scope;
  [%expect
    {|
    ./articles/first-article.md is unscoped by scope: ./_site
    ./../etc/passwd is unscoped by scope: ./_site
    |}]

let%expect_test "target - a traversal coming back into the target is legit" =
  let ws = Workspace.make () in
  let scope = ws.target_scope in
  Workspace.from_target ws [ ".."; "_site"; "index.html" ] |> check ~scope;
  [%expect {| ./_site/index.html is ok |}]

let%expect_test "cache - storing build artifacts" =
  let ws = Workspace.make () in
  let scope = ws.cache_scope in
  Workspace.from_cache ws [ "deps.sexp" ] |> check ~scope;
  Workspace.from_cache ws [ "pident"; "articles-first-article" ] |> check ~scope;
  Workspace.from_cache ws [ ".."; "_site"; "index.html" ] |> check ~scope;
  [%expect
    {|
    ./_cache/deps.sexp is ok
    ./_cache/pident/articles-first-article is ok
    ./_site/index.html is unscoped by scope: ./_cache
    |}]

(* {1 Server root} *)

let%expect_test "server root - layout" =
  Workspace.make ~server_root:[ "blog" ] () |> dump_workspace;
  [%expect
    {|
    [x][x][ ].
    [x][ ][x]./_site/blog
    [x][x][x]./_cache
    [v][ ][ ]/blog
    |}]

let%expect_test "server root - writes are confined under the server root" =
  let ws = Workspace.make ~server_root:[ "blog" ] () in
  let scope = ws.target_scope in
  Workspace.from_target ws [ "index.html" ] |> check ~scope;
  Workspace.from_target ws [ ".."; "index.html" ] |> check ~scope;
  Workspace.from_target ws [ ".."; "other-site"; "index.html" ] |> check ~scope;
  [%expect
    {|
    ./_site/blog/index.html is ok
    ./_site/index.html is unscoped by scope: ./_site/blog
    ./_site/other-site/index.html is unscoped by scope: ./_site/blog
    |}]

(* {1 Cache stored in the target} *)

let cache_in_target () =
  Workspace.make ~cache:(fun ~target -> Path.(target / "_cache")) ()

let%expect_test "cache in target - layout" =
  cache_in_target () |> dump_workspace;
  [%expect
    {|
    [x][x][ ].
    [x][ ][x]./_site
    [x][x][x]./_site/_cache
    [v][ ][ ]
    |}]

let%expect_test "cache in target - the target cannot reach the cache" =
  let ws = cache_in_target () in
  let scope = ws.target_scope in
  Workspace.from_target ws [ "index.html" ] |> check ~scope;
  Workspace.from_target ws [ "_cache"; "deps.sexp" ] |> check ~scope;
  Workspace.from_target ws [ "_cache" ] |> check ~scope;
  [%expect
    {|
    ./_site/index.html is ok
    ./_site/_cache/deps.sexp overlap with: ./_site/_cache
    ./_site/_cache overlap with: ./_site/_cache
    |}]

let%expect_test "cache in target - the cache remains reachable" =
  (* The target is a parent of the cache, so it is not kept as an exclusion for
     the cache scope. *)
  let ws = cache_in_target () in
  let scope = ws.cache_scope in
  Workspace.from_cache ws [ "deps.sexp" ] |> check ~scope;
  Workspace.from_cache ws [ ".."; "index.html" ] |> check ~scope;
  [%expect
    {|
    ./_site/_cache/deps.sexp is ok
    ./_site/index.html is unscoped by scope: ./_site/_cache
    |}]

let%expect_test "cache in target - the source cannot reach both of them" =
  let ws = cache_in_target () in
  let scope = ws.source_scope in
  Workspace.from_source ws [ "_site"; "index.html" ] |> check ~scope;
  Workspace.from_source ws [ "_site"; "_cache"; "deps.sexp" ] |> check ~scope;
  [%expect
    {|
    ./_site/index.html overlap with: ./_site
    ./_site/_cache/deps.sexp overlap with: ./_site
    |}]

let%expect_test "cache nested deeper in the target - creating a parent" =
  (* NOTE: [./_site/assets] contains the cache, so it is rejected by the target
     scope. It is the expected behaviour for a removal (removing [assets] would
     remove the cache) but creating [assets] (for example, as an intermediate
     directory) is not destructive. *)
  let ws =
    Workspace.make
      ~cache:(fun ~target -> Path.(target / "assets" / "_cache"))
      ()
  in
  let scope = ws.target_scope in
  Workspace.from_target ws [ "assets"; "style.css" ] |> check ~scope;
  Workspace.from_target ws [ "assets" ] |> check ~scope;
  [%expect
    {|
    ./_site/assets/style.css is ok
    ./_site/assets overlap with: ./_site/assets/_cache
    |}]

(* {1 Mixing absolute and relative paths} *)

let%expect_test "absolute source with a relative target" =
  (* NOTE: Known limitation (see the warning of [Tscope.make]): the target is
     relative while the source is absolute, so the target is never excluded from
     the source scope. Paths should be resolved beforehand. *)
  let ws = Workspace.make ~source:(Path.abs [ "home"; "user"; "site" ]) () in
  let scope = ws.source_scope in
  Workspace.from_source ws [ "articles"; "first-article.md" ] |> check ~scope;
  Workspace.from_source ws [ "_site"; "index.html" ] |> check ~scope;
  [%expect
    {|
    /home/user/site/articles/first-article.md is ok
    /home/user/site/_site/index.html is ok
    |}]

let%expect_test "absolute source and absolute target" =
  let ws =
    Workspace.make
      ~source:(Path.abs [ "home"; "user"; "site" ])
      ~target:(Path.abs [ "home"; "user"; "site"; "_site" ])
      ~cache:(fun ~target:_ -> Path.abs [ "home"; "user"; "site"; "_cache" ])
      ()
  in
  let scope = ws.source_scope in
  Workspace.from_source ws [ "articles"; "first-article.md" ] |> check ~scope;
  Workspace.from_source ws [ "_site"; "index.html" ] |> check ~scope;
  Workspace.from_source ws [ "_cache"; "deps.sexp" ] |> check ~scope;
  [%expect
    {|
    /home/user/site/articles/first-article.md is ok
    /home/user/site/_site/index.html overlap with: /home/user/site/_site
    /home/user/site/_cache/deps.sexp overlap with: /home/user/site/_cache
    |}]

(* {1 Paths restored from the disk} *)

let%expect_test "restoring cached paths before checking them" =
  (* Paths stored in the cache (for example, dependencies) are dumped with their
     capabilities. When they are restored, the capabilities must match the
     expected ones before checking the scope. *)
  let ws = Workspace.make () in
  let restore (r, w, p) =
    match
      Tpath.as_concrete ~readable:Tbool.yes ~writable:Tbool.no
        (r, w, Path.from_string p)
    with
    | None -> print_endline (p ^ " has unexpected capabilities")
    | Some path -> check ~scope:ws.source_scope path
  in
  [
    (true, false, "./articles/first-article.md")
  ; (true, false, "./_site/index.html")
  ; (true, true, "./articles/second-article.md")
  ; (false, true, "./_site/articles/first-article.html")
  ]
  |> List.iter restore;
  [%expect
    {|
    ./articles/first-article.md is ok
    ./_site/index.html overlap with: ./_site
    ./articles/second-article.md has unexpected capabilities
    ./_site/articles/first-article.html has unexpected capabilities
    |}]

(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Virtfs

let ( let* ) = Result.bind
let ( let+ ) x f = Result.map f x

module type handler = sig
  val write_file : Path.t -> string -> unit
  val read_file : Path.t -> string
  val file_exists : Path.t -> bool
end

module IO = struct
  let write_file (module Fs : handler) path content =
    try Ok (Fs.write_file path content) with
    | exn ->
      (* Yes, this is an example so the error handling is not very
         advanced. *)
      Error exn
  ;;

  let read_file (module Fs : handler) path =
    try Ok (if Fs.file_exists path then Some (Fs.read_file path) else None) with
    | exn -> Error exn
  ;;

  let append_to_file (module Fs : handler) path new_content =
    let new_content =
      String.trim (new_content |> String.split_on_char '\n' |> String.concat " ")
    in
    let* old_content = read_file (module Fs) path in
    let total_content =
      Option.fold
        ~none:new_content
        ~some:(fun old_content -> String.trim old_content ^ "\n" ^ new_content)
        old_content
    in
    write_file (module Fs) path total_content
  ;;
end

module Task = struct
  type t = string

  let from_string_to_list str =
    str |> String.split_on_char '\n' |> List.map String.trim
  ;;

  let list (module Fs : handler) path =
    match
      let+ str = IO.read_file (module Fs) path in
      match str with
      | None -> []
      | Some x -> from_string_to_list x
    with
    | Ok l -> l
    | Error _ ->
      let () = prerr_endline "list: An error is occurend" in
      []
  ;;

  let save (module Fs : handler) path task =
    match IO.append_to_file (module Fs) path task with
    | Ok () -> ()
    | Error _ -> prerr_endline "save: An error is occurend"
  ;;

  let display (module Fs : handler) path =
    List.iter print_endline (list (module Fs) path)
  ;;
end

module Handler = struct
  let fs = ref Tree.Simple.(mount ~scope:Path.cwd [ dir ~name:"tasks" [] ])
  let file_exists path = Tree.Simple.is_file ~path !fs

  let write_file path content =
    let new_fs = Tree.Simple.write_file ~overwrite:true ~path content !fs in
    fs := new_fs
  ;;

  let read_file path = Tree.Simple.read_file ~path !fs
end

let p = Path.rel [ "tasks"; "list" ]

let%expect_test "Display the file system" =
  !Handler.fs |> Tree.tree |> print_endline;
  [%expect
    {|
    └─./
      └─tasks/
    |}]
;;

let%expect_test "Print the list of tasks" = Task.display (module Handler) p

let%expect_test "Save some taks" =
  let () = Task.save (module Handler) p "task a" in
  let () = Task.save (module Handler) p "task b" in
  let () = Task.save (module Handler) p "task c" in
  Task.display (module Handler) p;
  [%expect
    {|
    task a
    task b
    task c
    |}]
;;

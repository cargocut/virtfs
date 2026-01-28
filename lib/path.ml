(* Copyright (c) 2026, Cargocut and the Virtfs developpers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type t =
  | Absolute of string list
  | Relative of string list

let equal a b =
  match a, b with
  | Relative a, Relative b | Absolute a, Absolute b ->
    List.equal String.equal a b
  | Relative _, Absolute _ | Absolute _, Relative _ -> false
;;

let to_string = function
  | Relative [] -> "./"
  | Absolute [] -> "/"
  | Relative xs -> String.concat Filename.dir_sep ("." :: xs)
  | Absolute xs -> String.concat Filename.dir_sep ("" :: xs)
;;

let compare a b =
  match a, b with
  | Relative _, Absolute _ -> -1
  | Absolute _, Relative _ -> 1
  | Absolute a, Absolute b | Relative a, Relative b ->
    (* OKAY: It seems fine to me to use a lexicographical order and
       not take into account the length of lists and segments to
       obtain an acceptable order in Sets or Maps. *)
    List.compare String.compare a b
;;

let split_on_chars pred s =
  (* NOTE: Like in [Stdlib] but using a predicate ([char -> bool])
     instead of a simple char. *)
  let r = ref [] in
  let j = ref (String.length s) in
  for i = String.length s - 1 downto 0 do
    if pred (String.unsafe_get s i)
    then (
      r := String.sub s (i + 1) (!j - i - 1) :: !r;
      j := i)
  done;
  String.sub s 0 !j :: !r
;;

let split_separator =
  split_on_chars (function
    | '/' | '\\' ->
      (* KLUDGE: Experience has shown that in YOCaml, being a
         little lax about path management is quite acceptable. By
         not using [Filename.dir_sep], we can ‘potentially’ support
         more cases. *)
      true
    | _ -> false)
;;

let from_fragment_list ?(prefix = []) fragments =
  (* NOTE: In other experiments, paths are stored in reverse order to
     facilitate queue processing: however, it would appear that more
     paths are created than are manipulated. In order to simplify the
     resolution of paths such as [‘../../f’], I have decided to keep
     the paths in the correct order. *)
  let rec aux from curr fragments =
    (* NOTE: Remove [".."] and ["."]  where possible.*)
    match from, curr, fragments with
    | (([] | ".." :: _) as fs), ".." :: ps, xs ->
      (* Deal with sequence of leading [".."]*)
      aux (".." :: fs) ps xs
    | fs, "." :: ps, xs | _ :: fs, ".." :: ps, xs ->
      (* Remove ["."] or [".."] (and collapse). *)
      aux fs ps xs
    | fs, x :: xs, ps ->
      (* Move the segment to the analyzed part. *)
      aux (x :: fs) xs ps
    | fs, [], x :: xs ->
      (* Split by potential separators inside the observable part. *)
      aux fs (split_separator x) xs
    | fs, [], [] ->
      (* Works done. *)
      List.rev fs
  in
  aux (List.rev prefix) [] fragments
;;

let abs fragments =
  Absolute
    (fragments
     |> from_fragment_list
     |> List.drop_while (String.equal "..")
        (* OKAY: When you [cd ..] to the root (["/"]) of a Unix file
           system, you remain at the root. Therefore, ["/.."] =
           ["/"]. Hence the removal of the prefixes [".."]. *))
;;

let rel fragments = Relative (from_fragment_list fragments)
let cwd = Relative []
let root = Absolute []

let from_string s =
  match split_separator s with
  | "." :: xs -> rel xs
  | "" :: xs -> abs xs
  | xs -> rel xs
;;

let of_string = from_string

let fragments = function
  | Relative xs | Absolute xs -> xs
;;

let to_list = fragments

let is_relative = function
  | Relative _ -> true
  | Absolute _ -> false
;;

let is_absolute = function
  | Relative _ -> false
  | Absolute _ -> true
;;

let is_cwd = function
  | Relative [] ->
    (* MAYBE: In the case of resolutions (e.g. switching from
       ["foo/.."]), the test is not sufficient. To be corrected when
       the resolution takes effect.*)
    true
  | _ -> false
;;

let is_root = function
  | Absolute [] -> true
  | _ ->
    (* KLUDGE: Some root opportunities may be missed if [cwd] = [root]
       or if the resolution of [cwd] points to the root. However, I do
       not believe there is a straightforward way to fix this while
       remaining abstract. *)
    false
;;

let parent p =
  let xs = fragments p in
  (* KLUDGE: How does it behave in the presence of leading ".."?  In
     the parent implementation, the parent of ["../.."] is [".."],
     which is strange, but it follows the convention of the Unix
     [dirname] implementation. *)
  let rec aux acc = function
    | [] -> if is_relative p then rel [ ".." ] else root
    | [ _ ] ->
      let xs = List.rev acc in
      if is_relative p then rel xs else abs xs
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] xs
;;

let dirname = parent

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

let from_fragment_list fragments =
  (* NOTE: In other experiments, paths are stored in reverse order to
     facilitate queue processing: however, it would appear that more
     paths are created than are manipulated. In order to simplify the
     resolution of paths such as [‘../../f’], I have decided to keep
     the paths in the correct order. *)
  fragments
  |> List.concat_map (fun fragment ->
    fragment
    |> split_on_chars (function
      | '/' | '\\' ->
        (* KLUDGE: Experience has shown that in YOCaml, being a
           little lax about path management is quite acceptable. By
           not using [Filename.dir_sep], we can ‘potentially’ support
           more cases. *)
        true
      | _ -> false))
;;

let abs fragments = Absolute (from_fragment_list fragments)
let rel fragments = Relative (from_fragment_list fragments)

let is_relative = function
  | Relative _ -> true
  | Absolute _ -> false
;;

let is_absolute = function
  | Relative _ -> false
  | Absolute _ -> true
;;

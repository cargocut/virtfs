(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type (!'concrete, !'readable, !'writable) t = {
    path : ('concrete, 'readable, 'writable) Tpath.t
  ; exclusions : Path.t list
}

type error =
  | Unscoped_by of { scope : Path.t; path : Path.t }
  | Overlap_with of { path : Path.t; overlapping : Path.t }

let make ?(exclusions = []) path = { path; exclusions }

let check ~scope:{ path = global; exclusions } path =
  let parent = global |> Tpath.path and current = Tpath.path path in
  if Path.is_scoped_by ~strict:true ~parent current then
    (* The path seems legit, but we want to explore the exclusion list to be
       sure that it is.

       NOTE: An exclusion whose kind (absolute or relative) differs from the
       kind of [current] can never match, so it is silently ignored. See the
       warning in the documentation of {!val:make}. *)
    let from_exclusions =
      List.find_opt
        (fun excluded ->
          Path.is_scoped_by ~strict:false ~parent:excluded current
          || Path.is_scoped_by ~strict:false ~parent:current excluded)
        exclusions
    in
    match from_exclusions with
    | None -> Ok () (* Happy Path! *)
    | Some excluded ->
        (* Overlapping with a path from the list. *)
        let overlapping = excluded and path = current in
        Error (Overlap_with { path; overlapping })
  else
    (* The path is not scoped by the given scope. *)
    let scope = parent and path = current in
    Error (Unscoped_by { scope; path })

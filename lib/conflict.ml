(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type ('a, 'metadata) give_up =
  previous:('a, 'metadata) Item.t
  -> current:('a, 'metadata) Item.t
  -> Path.t
  -> [ `Previous | `Current | `Neither ]

type ('a, 'metadata) resolution =
  previous:('a, 'metadata) Item.t
  -> current:('a, 'metadata) Item.t
  -> Path.t
  -> ('a, 'metadata) Item.t list

let retain x ~previous:_ ~current:_ _ = x
let keep_current ~previous:_ ~current _ = [ current ]
let keep_previous ~previous ~current:_ _ = [ previous ]
let discard ~previous:_ ~current:_ _ = []

let rename_current rename ~previous ~current _ =
  [ previous; Item.rename (rename (Item.name current)) current ]
;;

let rename_previous rename ~previous ~current _ =
  [ Item.rename (rename (Item.name previous)) previous; current ]
;;

let rename_both ~on_previous:f ~on_current:g ~previous ~current _ =
  [ Item.rename (f (Item.name previous)) previous
  ; Item.rename (g (Item.name current)) current
  ]
;;

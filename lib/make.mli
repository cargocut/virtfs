(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** A set of functors useful for generalising behaviours. *)

module Scoped () : Intf.WITH_SCOPE_BUILDER
(** Allows you to create one of the scopes. The API exposes scope creation, but
    from a user’s perspective, you would probably want to constrain the
    signature as follows {!module-type:Intf.WITH_SCOPE}. *)

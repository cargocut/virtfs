(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Reusable interfaces for enforcing certain invariants. *)

(** {1 About Scope}

    To be effective, scopes should be private, or should not be constructible
    from outside. We therefore expose two signatures: one for composing with the
    implementation, which exposes a local way of constructing scopes, and one
    for composing with the interface, which hides the ability to create scopes.
*)

module type WITH_SCOPE = sig
  (** Describes a public API (which allows scopes to be validated, but not
      created). *)

  type (!'concrete, !'readable, !'writable) scope
  (** The type describing a scope (based on {!module:Tscope}). *)

  val check_scope :
       scope:('concrete, 'readable, 'writable) scope
    -> ('concrete, 'readable, 'writable) Tpath.t
    -> (unit, Tscope.error) result
  (** See {!val:Tscope.check}. *)
end

module type WITH_SCOPE_BUILDER = sig
  include WITH_SCOPE
  (** @inline *)

  (** {1 Private API}

      Allows you to create a scope locally within the module. *)

  val make_scope :
       ?exclusions:Path.t list
    -> ('concrete, 'readable, 'writable) Tpath.t
    -> ('concrete, 'readable, 'writable) scope
  (** See {!val:Tscope.make}. *)
end

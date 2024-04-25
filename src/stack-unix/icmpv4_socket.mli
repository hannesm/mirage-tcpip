type t

val connect : unit -> t Lwt.t

val disconnect : t -> unit Lwt.t

type ipaddr = Ipaddr.V4.t
(** The type for IP addresses. *)

type error (* entirely abstract since we expose none in an Icmp module *)
(** The type for ICMP errors. *)

val pp_error: error Fmt.t
(** [pp_error] is the pretty-printer for errors. *)

val input : t -> src:ipaddr -> dst:ipaddr -> Cstruct.t -> unit Lwt.t
(** [input t src dst buffer] reacts to the ICMP message in
      [buffer]. *)

val write : t -> ?src:ipaddr -> dst:ipaddr -> ?ttl:int -> Cstruct.t -> (unit, error) result Lwt.t
(** [write t ~src ~dst ~ttl buffer] sends the ICMP message in [buffer] to [dst]
      over IP. Passes the time-to-live ([ttl]) to the IP stack if given. *)


val listen : t -> ipaddr -> (Cstruct.t -> unit Lwt.t) -> unit Lwt.t
(** [listen t addr fn] attempts to create an unprivileged listener on IP address [addr].

    When a packet is received, the callback [fn] will be called in a fresh background
    thread. The callback will be provided a buffer containing an IP datagram with an
    ICMP payload inside.

    The thread returned by [listen] blocks until the stack is disconnected.
*)

(** {2 ICMP layer} *)

(** Internet Control Message Protocol: error messages and operational
    information. *)
  type t
  (** The type representing the internal state of the ICMP layer. *)

  val connect : Ipv4.t -> t Lwt.t

  val disconnect: t -> unit Lwt.t
  (** Disconnect from the ICMP layer. While this might take some time to
      complete, it can never result in an error. *)

  type error (* entirely abstract since we expose none in an Icmp module *)
  (** The type for ICMP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  val input : t -> src:Ipaddr.V4.t -> dst:Ipaddr.V4.t -> Cstruct.t -> unit Lwt.t
  (** [input t src dst buffer] reacts to the ICMP message in
      [buffer]. *)

  val write : t -> ?src:Ipaddr.V4.t -> dst:Ipaddr.V4.t -> ?ttl:int -> Cstruct.t -> (unit, error) result Lwt.t
  (** [write t ~src ~dst ~ttl buffer] sends the ICMP message in [buffer] to [dst]
      over IP. Passes the time-to-live ([ttl]) to the IP stack if given. *)

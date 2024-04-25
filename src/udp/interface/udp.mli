(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)
(** User datagram protocol layer: connectionless message-oriented
    communication. *)

  type error (* entirely abstract since we expose none in a Udp module *)
  (** The type for UDP errors. *)

  val pp_error: error Fmt.t
  (** [pp] is the pretty-printer for errors. *)

  type t
  (** The type representing the internal state of the UDP layer. *)

val connect : Ipv4v6.t -> t Lwt.t

val disconnect: t -> unit Lwt.t
  (** Disconnect from the UDP layer. While this might take some time to
      complete, it can never result in an error. *)

  type callback = src:Ipaddr.t -> dst:Ipaddr.t -> src_port:int -> Cstruct.t -> unit Lwt.t
  (** The type for callback functions that adds the UDP metadata for
      [src] and [dst] IP addresses, the [src_port] of the
      connection and the [buffer] payload of the datagram. *)

  val listen : t -> port:int -> callback -> unit
  (** [listen t ~port callback] executes [callback] for each packet received
      on [port].

      @raise Invalid_argument if [port < 0] or [port > 65535] *)

  val unlisten : t -> port:int -> unit
  (** [unlisten t ~port] stops any listeners on [port]. *)

  val input: t -> src:Ipaddr.t -> dst:Ipaddr.t -> Cstruct.t -> unit Lwt.t
  (** [input t] demultiplexes incoming datagrams based on
      their destination port. *)

  val write: ?src:Ipaddr.t -> ?src_port:int -> ?ttl:int -> dst:Ipaddr.t ->
    dst_port:int -> t -> Cstruct.t -> (unit, error) result Lwt.t
  (** [write ~src ~src_port ~ttl ~dst ~dst_port udp data] is a task
      that writes [data] from an optional [src] and [src_port] to a [dst]
      and [dst_port] IP address pair. An optional time-to-live ([ttl]) is passed
      through to the IP layer. *)



  type t
  (** The type representing the internal state of the dual IPv4 and IPv6 stack. *)

val connect : ?netif:Mirage_net.t -> ?ethernet:Ethernet.t -> ?arp:Arp.t ->
  ?icmp:Icmpv4.t -> ip:Ipv4v6.t -> udp:Udp.t -> tcp:Tcp.t -> unit -> t Lwt.t

  val disconnect: t -> unit Lwt.t
  (** Disconnect from the dual IPv4 and IPv6 stack. While this might take some
      time to complete, it can never result in an error. *)

  module UDP: module type of Udp

  module TCP: module type of Tcp

  module IP: module type of Ipv4v6

  val udp: t -> UDP.t
  (** [udp t] obtains a descriptor for use with the [UDP] module,
      usually to transmit traffic. *)

  val tcp: t -> TCP.t
  (** [tcp t] obtains a descriptor for use with the [TCP] module,
      usually to initiate outgoing connections. *)

  val ip: t -> IP.t
  (** [ip t] obtains a descriptor for use with the [IP] module,
      which can handle raw IPv4 and IPv6 frames, or manipulate IP address
      configuration on the stack interface. *)

  val listen: t -> unit Lwt.t
  (** [listen t] requests that the stack listen for traffic on the
      network interface associated with the stack, and demultiplex
      traffic to the appropriate callbacks. *)

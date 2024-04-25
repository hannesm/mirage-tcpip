
include Tcpip.Ip.S with type ipaddr = Ipaddr.t

val connect : ipv4_only:bool -> ipv6_only:bool -> Static_ipv4.t -> Ipv6.t -> t Lwt.t


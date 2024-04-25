
include Tcpip.Ip.S with type ipaddr = Ipaddr.t

val connect : ipv4_only:bool -> ipv6_only:bool -> Ipv4.t -> Ipv6.t -> t Lwt.t


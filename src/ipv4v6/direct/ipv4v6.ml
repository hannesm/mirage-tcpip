open Lwt.Infix

let src = Logs.Src.create "tcpip-ipv4v6" ~doc:"Pure OCaml TCP/IP stack"
module Log = (val Logs.src_log src : Logs.LOG)

type ipaddr   = Ipaddr.t
  type callback = src:ipaddr -> dst:ipaddr -> Cstruct.t -> unit Lwt.t

  let pp_ipaddr = Ipaddr.pp

  type error = [ Tcpip.Ip.error | `Ipv4 of Ipv4.error | `Ipv6 of Ipv6.error | `Msg of string ]

  let pp_error ppf = function
    | #Tcpip.Ip.error as e -> Tcpip.Ip.pp_error ppf e
    | `Ipv4 e -> Ipv4.pp_error ppf e
    | `Ipv6 e -> Ipv6.pp_error ppf e
    | `Msg m -> Fmt.string ppf m

  type t = { ipv4 : Ipv4.t ; ipv4_only : bool ; ipv6 : Ipv6.t ; ipv6_only : bool }

  let connect ~ipv4_only ~ipv6_only ipv4 ipv6 =
    if ipv4_only && ipv6_only then
      Lwt.fail_with "cannot configure stack with both IPv4 only and IPv6 only"
    else
      Lwt.return { ipv4 ; ipv4_only ; ipv6 ; ipv6_only }

  let disconnect _ = Lwt.return_unit

  let input t ~tcp ~udp ~default =
    let tcp4 ~src ~dst payload = tcp ~src:(Ipaddr.V4 src) ~dst:(Ipaddr.V4 dst) payload
    and tcp6 ~src ~dst payload = tcp ~src:(Ipaddr.V6 src) ~dst:(Ipaddr.V6 dst) payload
    and udp4 ~src ~dst payload = udp ~src:(Ipaddr.V4 src) ~dst:(Ipaddr.V4 dst) payload
    and udp6 ~src ~dst payload = udp ~src:(Ipaddr.V6 src) ~dst:(Ipaddr.V6 dst) payload
    and default4 ~proto ~src ~dst payload = default ~proto ~src:(Ipaddr.V4 src) ~dst:(Ipaddr.V4 dst) payload
    and default6 ~proto ~src ~dst payload = default ~proto ~src:(Ipaddr.V6 src) ~dst:(Ipaddr.V6 dst) payload
    in
    fun buf ->
      if Cstruct.length buf >= 1 then
        let v = Cstruct.get_uint8 buf 0 lsr 4 in
        if v = 4 && not t.ipv6_only then
          Ipv4.input t.ipv4 ~tcp:tcp4 ~udp:udp4 ~default:default4 buf
        else if v = 6 && not t.ipv4_only then
          Ipv6.input t.ipv6 ~tcp:tcp6 ~udp:udp6 ~default:default6 buf
        else
          Lwt.return_unit
      else
        Lwt.return_unit

  let write t ?fragment ?ttl ?src dst proto ?size headerf bufs =
    match dst with
    | Ipaddr.V4 dst ->
      if not t.ipv6_only then
        match
          match src with
          | None -> Ok None
          | Some (Ipaddr.V4 src) -> Ok (Some src)
          | _ -> Error (`Msg "source must be V4 if dst is V4")
        with
        | Error e -> Lwt.return (Error e)
        | Ok src ->
          Ipv4.write t.ipv4 ?fragment ?ttl ?src dst proto ?size headerf bufs >|= function
          | Ok () -> Ok ()
          | Error e -> Error (`Ipv4 e)
      else begin
        Log.warn (fun m -> m "attempted to write an IPv4 packet in a v6 only stack");
        Lwt.return (Ok ())
      end
    | Ipaddr.V6 dst ->
      if not t.ipv4_only then
        match
          match src with
          | None -> Ok None
          | Some (Ipaddr.V6 src) -> Ok (Some src)
          | _ -> Error (`Msg "source must be V6 if dst is V6")
        with
        | Error e -> Lwt.return (Error e)
        | Ok src ->
          Ipv6.write t.ipv6 ?fragment ?ttl ?src dst proto ?size headerf bufs >|= function
          | Ok () -> Ok ()
          | Error e -> Error (`Ipv6 e)
      else begin
        Log.warn (fun m -> m "attempted to write an IPv6 packet in a v4 only stack");
        Lwt.return (Ok ())
      end

  let pseudoheader t ?src dst proto len =
    match dst with
    | Ipaddr.V4 dst ->
      let src =
        match src with
        | None -> None
        | Some (Ipaddr.V4 src) -> Some src
        | _ -> None (* cannot happen *)
      in
      Ipv4.pseudoheader t.ipv4 ?src dst proto len
    | Ipaddr.V6 dst ->
      let src =
        match src with
        | None -> None
        | Some (Ipaddr.V6 src) -> Some src
        | _ -> None (* cannot happen *)
      in
      Ipv6.pseudoheader t.ipv6 ?src dst proto len

  let src t ~dst =
    match dst with
    | Ipaddr.V4 dst -> Ipaddr.V4 (Ipv4.src t.ipv4 ~dst)
    | Ipaddr.V6 dst -> Ipaddr.V6 (Ipv6.src t.ipv6 ~dst)

  let get_ip t =
    List.map (fun ip -> Ipaddr.V4 ip) (Ipv4.get_ip t.ipv4) @
    List.map (fun ip -> Ipaddr.V6 ip) (Ipv6.get_ip t.ipv6)

  let mtu t ~dst = match dst with
    | Ipaddr.V4 dst -> Ipv4.mtu t.ipv4 ~dst
    | Ipaddr.V6 dst -> Ipv6.mtu t.ipv6 ~dst

(*
 * Copyright (c) 2011-2014 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt.Infix

let src = Logs.Src.create "tcpip-stack-direct" ~doc:"Pure OCaml TCP/IP stack"
module Log = (val Logs.src_log src : Logs.LOG)


  type t = {
    netif : Mirage_net.t;
    ethif : Ethernet.t;
    arpv4 : Arp.t;
    icmpv4 : Icmpv4.t;
    ip : Ipv4v6.t;
    udp : Udp.t;
    tcp : Tcp.t;
    mutable task : unit Lwt.t option;
  }

  let pp fmt t =
    Format.fprintf fmt "mac=%a,ip=%a" Macaddr.pp (Ethernet.mac t.ethif)
      Fmt.(list ~sep:(any ", ") Ipaddr.pp) (Ipv4v6.get_ip t.ip)

  let tcp { tcp; _ } = tcp
  let udp { udp; _ } = udp
  let ip { ip; _ } = ip

  let listen t =
    Lwt.catch (fun () ->
        Log.debug (fun f -> f "Establishing or updating listener for stack %a" pp t);
        let tcp = Tcp.input t.tcp
        and udp = Udp.input t.udp
        and default ~proto ~src ~dst buf =
          match proto, src, dst with
          | 1, Ipaddr.V4 src, Ipaddr.V4 dst -> Icmpv4.input t.icmpv4 ~src ~dst buf
          | _ -> Lwt.return_unit
        in
        let ethif_listener = Ethernet.input
            ~arpv4:(Arp.input t.arpv4)
            ~ipv4:(Ipv4v6.input ~tcp ~udp ~default t.ip)
            ~ipv6:(Ipv4v6.input ~tcp ~udp ~default t.ip)
            t.ethif
        in
        Mirage_net.listen t.netif ~header_size:Ethernet.Packet.sizeof_ethernet ethif_listener
        >>= function
        | Error e ->
          Log.warn (fun p -> p "%a" Mirage_net.pp_error e) ;
          (* XXX: error should be passed to the caller *)
          Lwt.return_unit
        | Ok _res ->
          let nstat = Mirage_net.get_stats_counters t.netif in
          Log.info (fun f ->
              f "listening loop of interface %s terminated regularly:@ %Lu bytes \
                 (%lu packets) received, %Lu bytes (%lu packets) sent@ "
                (Macaddr.to_string (Mirage_net.mac t.netif))
                nstat.rx_bytes nstat.rx_pkts
                nstat.tx_bytes nstat.tx_pkts) ;
          Lwt.return_unit)
      (function
        | Lwt.Canceled ->
          Log.info (fun f -> f "listen of %a cancelled" pp t);
          Lwt.return_unit
        | e -> Lwt.fail e)

let connect ?netif ?ethernet ?arp ?icmp ~ip ~udp ~tcp () =
  let err x msg = match x with None -> failwith msg | Some x -> x in
  let netif = err netif "no network interface provided"
  and ethif = err ethernet "no Ethernet layer provided"
  and arpv4 = err arp "no ARP handler specified"
  and icmpv4 = err icmp "no ICMP layer specified"
  in
  let t = { netif; ethif; arpv4; ip; icmpv4; tcp; udp; task = None } in
  Log.info (fun f -> f "Dual TCP/IP stack assembled: %a" pp t);
  Lwt.async (fun () -> let task = listen t in t.task <- Some task; task);
  Lwt.return t

  let disconnect t =
    Log.info (fun f -> f "Dual TCP/IP stack disconnected: %a" pp t);
    (match t.task with None -> () | Some task -> Lwt.cancel task);
    Lwt.return_unit

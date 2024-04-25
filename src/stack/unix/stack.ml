(*
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
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

let src = Logs.Src.create "tcpip-stack-socket" ~doc:"Platform's native TCP/IP stack"
module Log = (val Logs.src_log src : Logs.LOG)

type t = {
  ip : Ipv4v6.t;
    udp : Udp.t;
    tcp : Tcp.t;
    stop : unit Lwt.u;
    switched_off : unit Lwt.t;
  }

  let udp { udp; _ } = udp
  let tcp { tcp; _ } = tcp
  let ip { ip; _ } = ip

  let listen t = t.switched_off

  let connect ?netif:_ ?ethernet:_ ?arp:_ ?icmp:_ ~ip ~udp ~tcp () =
    Log.info (fun f -> f "Dual IPv4 and IPv6 socket stack: connect");
    let switched_off, stop = Lwt.wait () in
    Lwt.return { ip; tcp; udp; stop; switched_off }

  let disconnect t =
    Tcp.disconnect t.tcp >>= fun () ->
    Udp.disconnect t.udp >|= fun () ->
    Lwt.wakeup_later t.stop ()

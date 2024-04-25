(** Transmission Control Protocol layer: reliable ordered streaming
    communication. *)
type nonrec error = private [> Tcp_error.read]
(** The type for TCP errors. *)

type nonrec write_error = private [> Tcp_error.write]
(** The type for TCP write errors. *)

type flow
(** A flow represents the state of a single TCP stream that is connected
    to an endpoint. *)

type t
(** The type representing the internal state of the TCP layer. *)

val connect : Ipv4v6.t -> t Lwt.t

val disconnect: t -> unit Lwt.t
  (** Disconnect from the TCP layer. While this might take some time to
      complete, it can never result in an error. *)

  include Mirage_flow.S with
      type flow   := flow
  and type error  := error
  and type write_error := write_error

  val dst: flow -> Ipaddr.t * int
  (** Get the destination IP address and destination port that a
      flow is currently connected to. *)

  val src : flow -> Ipaddr.t * int
  (** Get the source IP address and source port that a flow is currently
      connected to. *)

  val write_nodelay: flow -> Cstruct.t -> (unit, write_error) result Lwt.t
  (** [write_nodelay flow buffer] writes the contents of [buffer]
      to the flow. The thread blocks until all data has been successfully
      transmitted to the remote endpoint.
      Buffering within the layer is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val writev_nodelay: flow -> Cstruct.t list -> (unit, write_error) result Lwt.t
  (** [writev_nodelay flow buffers] writes the contents of [buffers]
      to the flow. The thread blocks until all data has been successfully
      transmitted to the remote endpoint.
      Buffering within the layer is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val create_connection: ?keepalive:Tcp_keepalive.t -> t -> Ipaddr.t * int -> (flow, error) result Lwt.t
  (** [create_connection ~keepalive t (addr,port)] opens a TCP connection
      to the specified endpoint.

      If the optional argument [?keepalive] is provided then TCP keep-alive
      messages will be sent to the server when the connection is idle. If
      no responses are received then eventually the connection will be disconnected:
      [read] will return [Ok `Eof] and write will return [Error `Closed] *)

  val listen : t -> port:int -> ?keepalive:Tcp_keepalive.t -> (flow -> unit Lwt.t) -> unit
  (** [listen t ~port ~keepalive callback] listens on [port]. The [callback] is
      executed for each flow that was established. If [keepalive] is provided,
      this configuration will be applied before calling [callback].

      @raise Invalid_argument if [port < 0] or [port > 65535]
 *)

  val unlisten : t -> port:int -> unit
  (** [unlisten t ~port] stops any listener on [port]. *)

  val input: t -> src:Ipaddr.t -> dst:Ipaddr.t -> Cstruct.t -> unit Lwt.t
  (** [input t] returns an input function continuation to be
      passed to the underlying {!IP} layer. *)

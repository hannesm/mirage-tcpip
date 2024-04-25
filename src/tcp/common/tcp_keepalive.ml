(** Configuration for TCP keep-alives.
    Keep-alive messages are probes sent on an idle connection. If no traffic
    is received after a certain number of probes are sent, then the connection
    is assumed to have been lost. *)
  type t = {
    after: Duration.t;    (** initial delay before sending probes on an idle
                              connection *)
    interval: Duration.t; (** interval between successive probes *)
    probes: int;          (** total number of probes to send before assuming
                              that, if the connection is still idle it has
                              been lost *)
  }
  (** Configuration for TCP keep-alives *)

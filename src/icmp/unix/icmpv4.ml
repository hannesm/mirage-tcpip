type t = unit

let connect _ = Lwt.return_unit

let disconnect _ = Lwt.return_unit

type error = [ `Empty ]

let pp_error _ _ = ()

let input _t ~src:_ ~dst:_ _data = Lwt.return_unit

let write _t ?src:_ ~dst:_ ?ttl:_ _data = Lwt.return (Ok ())

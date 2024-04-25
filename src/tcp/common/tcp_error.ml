type read = [ `Timeout | `Refused]
type write = [ read | Mirage_flow.write_error ]

let pp_read ppf = function
  | `Timeout -> Fmt.string ppf "connection attempt timed out"
  | `Refused -> Fmt.string ppf "connection attempt was refused"

let pp_write ppf = function
  | #Mirage_flow.write_error as e -> Mirage_flow.pp_write_error ppf e
  | #read as e                   -> pp_read ppf e

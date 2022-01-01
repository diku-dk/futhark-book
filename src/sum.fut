module type monoid = {
  type t
  val add : t -> t -> t
  val zero : t
}

module sum (M: monoid) = {
  def sum (a: []M.t): M.t =
    reduce M.add M.zero a
}

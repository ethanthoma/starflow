//import gleeunit
import gleam/io
import gleam/result
import starflow_test/joke_test as test_case

pub fn main() {
  //gleeunit.main()

  use err <- result.map_error(test_case.test_case())
  io.println_error(err)
}

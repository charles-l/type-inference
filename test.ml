open Ast

module NameMap = Map.Make(String)

let rec get_ids (e: expr): id list =
  let rec dedup = function
   | [] -> []
   | x :: y :: xs when x = y -> y :: dedup xs
   | x :: xs -> x :: dedup xs in
  let ids = match e with
   | NumLit(_) | BoolLit(_) -> []
   | Val(x) -> [x]
   | Fun(x, y) -> [x] @ (get_ids y)
   | Binop(e1, _, e2) -> (get_ids e1) @ (get_ids e2)
   | App(fn, arg) -> (get_ids fn) @ (get_ids arg) in
 dedup ids
;;

let debug (e: expr): string =
  let ids = get_ids e in
  let env = ListLabels.fold_left ~init:NameMap.empty ids
     ~f:(fun m x -> NameMap.add x (Infer.gen_new_type ()) m) in
  let aexpr = Infer.infer env e in
  string_of_type (Infer.type_of aexpr)
;;

let testcases = [|
  NumLit(10);
  BoolLit(true);
  Binop(Binop(Val("x"), Add, Val("y")), Mul, Val("z"));
  Binop(Binop(Val("x"), Add, Val("y")), Gt, Val("z"));
  Binop(Binop(Val("x"), Gt, Val("y")), Lt, Val("z"));
  Binop(Binop(Val("x"), Mul, Val("y")), Lt, Binop(Val("z"), Add, Val("w")));
  Binop(Binop(Val("x"), Gt, Val("y")), Lt, Binop(Val("z"), Lt, Val("w")));
  Fun("x", Binop(Val("x"), Add, NumLit(10)));
  Fun("x", Binop(NumLit(20), Gt,Binop(Val("x"), Add, NumLit(10))));
  Fun("f", Fun("g", Fun("x", App(Val("f"), App(Val("g"), Val("x"))))));
|];;

let literals_check () = 
  begin
    Alcotest.(check string) "Integer" "int" (debug testcases.(0));
    Alcotest.(check string) "Boolean" "bool" (debug testcases.(1));
  end
;;


let infer_set = [
  "Literals", `Quick, literals_check;
]

(* Run it *)
let () =
  Alcotest.run "Type-inference testcases" [
    "test_1", infer_set;
  ]
;;

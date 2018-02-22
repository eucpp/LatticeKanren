open OUnit2
open Lkanren.Symbolic
open Lkanren.TreeEqSolver

module Goal = Lkanren.Goal.Make(Lkanren.TreeEqSolver)

open Goal

module Fresh =
  struct
    (* let one f = lift @@ fresh f *)
    let one f =
      let a = Var (Var.fresh ()) in
      f a

    let two f =
      let a = Var (Var.fresh ()) in
      let b = Var (Var.fresh ()) in
      f a b

    let three f =
      let a = Var (Var.fresh ()) in
      let b = Var (Var.fresh ()) in
      let c = Var (Var.fresh ()) in
      f a b c

    let four f =
      let a = Var (Var.fresh ()) in
      let b = Var (Var.fresh ()) in
      let c = Var (Var.fresh ()) in
      let d = Var (Var.fresh ()) in
      f a b c d
  end

let nil       = Func ("Nil" , [])
let single x  = Func ("Cons", [x; nil])
let cons x xs = Func ("Cons", [x; xs])

let tuple xs = Func ("", xs)

let of_list xs =
  ListLabels.fold_right xs ~init:nil ~f:cons

let of_ilist is =
  of_list @@ List.map (fun i -> Func (string_of_int i, [])) is

let (?&) ss = lift @@
  ListLabels.fold_left ss ~init:top
    ~f:(fun s s' ->
      (* Printf.printf "\nmeeting %s and %s\n" (show s) (show s'); *)
      meet s s'
    )

let rec appendo a b ab = Goal.(
  (?&
    [ (a === nil)
    ; (b === ab)
    ]
  )
  <|>
  (delay @@ fun () -> Fresh.three (fun h t ab' ->
    (?&
      [ (a  === cons h t)
      ; (ab === cons h ab')
      ]
    )
    <&>
      (appendo t b ab')
  ))
)

(* let rec reverso a b =
  (?&
    [ (a === nil)
    ; (b === nil)
    ]
  )
  |||
  (Fresh.four (fun h t hs a' ->
    (?&
      [ (a  === cons h t)
      ; (hs === single h)
      ]
    )
    &&&
      (reverso t a')
    &&&
      (appendo a' hs b)
    )
  ) *)

module Run =
  struct
    let one ?n g =
      let q = Var (Var.fresh ()) in
      ListLabels.fold_right (run ?n @@ g q) ~init:[]
        ~f:(fun s acc ->
          match reify q s with None -> acc | Some q -> q::acc
        )

    let two ?n g =
      let q = Var (Var.fresh ()) in
      let r = Var (Var.fresh ()) in
      ListLabels.fold_right (run ?n @@ g q) ~init:[]
        ~f:(fun s acc ->
          match reify (tuple [q;r]) s with None -> acc | Some q -> q::acc
        )

  end

let assert_list_equal ?cmp ?printer xs ys =
  let xl, yl = List.length xs, List.length ys in
  let msg = Printf.sprintf "Lists have different length: expected %d, actual %d" xl yl in
  assert_equal ~msg xl yl;
  List.iter2 (fun x y -> assert_equal ?cmp ?printer x y) xs ys

let tests =
  "appendo" >:::
    [ "1" >:: (fun test_ctx ->
        let a = of_ilist [] in
        let b = of_ilist [1; 2] in
        let c = of_ilist [1; 2] in
        let answs = Run.one (fun q -> appendo a b q) in
        List.iter (fun x -> Printf.printf "\n%s\n" (Domain.show x)) answs;
        assert_list_equal ~cmp:Domain.equal [c] answs
      );

      "2" >:: (fun test_ctx ->
          let a = of_ilist [1;] in
          let b = of_ilist [2;] in
          let c = of_ilist [1; 2] in
          (* let [answ] = Run.one ~n:1 (fun q -> appendo a b q) in *)
          let answs = Run.one (fun q -> appendo a b q) in
          List.iter (fun x -> Printf.printf "\n%s\n" (Domain.show x)) answs;
          assert_list_equal ~cmp:Domain.equal ~printer:Domain.show [c] answs
        );

      "3" >:: (fun test_ctx ->
          let a = of_ilist [1;2] in
          let b = of_ilist [3;4] in
          let c = of_ilist [1; 2; 3; 4] in
          (* let [answ] = Run.one ~n:1 (fun q -> appendo a b q) in *)
          let answs = Run.one (fun q -> appendo a b q) in
          List.iter (fun x -> Printf.printf "\n%s\n" (Domain.show x)) answs;
          assert_list_equal ~cmp:Domain.equal ~printer:Domain.show [c] answs
        );

      "4" >:: (fun test_ctx ->
          let a = of_ilist [1;2] in
          let b = of_ilist [3;4] in
          let c = of_ilist [1; 2; 3; 4] in
          (* let [answ] = Run.one ~n:1 (fun q -> appendo a b q) in *)
          let answs = Run.one (fun q -> appendo a q c) in
          List.iter (fun x -> Printf.printf "\n%s\n" (Domain.show x)) answs;
          assert_list_equal ~cmp:Domain.equal ~printer:Domain.show [b] answs
        )

    ]

(* let main =
  let a = of_ilist [] in
  let b = of_ilist [1; 2] in
  let c = of_ilist [1; 2] in
  (* let [answ] = Run.one ~n:1 (fun q -> appendo a b q) in *)
  let answs = Run.one ~n:1 (fun q -> appendo a b q) in
  assert_list_equal ~cmp:Domain.equal [c] answs *)

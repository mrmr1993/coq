open Coqast
open Ast
open Pp
open Util
open Names
open Pcoq

exception Non_closed_number

let get_r_sign loc =
  let ast_of_id id = Astterm.globalize_constr (Nvar(loc,id)) in
  ((ast_of_id "R0", ast_of_id "R1", ast_of_id "Rplus", 
    ast_of_id "NRplus"))

let r_of_int n dloc =
  let (ast0,ast1,astp,_) = get_r_sign dloc in
  let rec mk_r n =
    if n <= 0 then 
      ast0
    else if n = 1 then 
      ast1
    else
      Node(dloc,"APPLIST", [astp; mk_r (n-1); ast1])
  in 
  mk_r n

let r_of_string s dloc = 
  r_of_int (int_of_string s) dloc

let rnumber = 
  match create_entry (get_univ "rnatural") "rnumber" ETast with
    | Ast n -> n
    | _ -> anomaly "G_rsyntax : create_entry rnumber failed"

let _ = 
  Gram.extend rnumber None
    [None, None,
     [[Gramext.Stoken ("INT", "")],
      Gramext.action r_of_string]]

(** pp **)

let rec int_of_r_rec ast1 astp p =
  match p with
    | Node (_,"APPLIST", [b; a; c]) when alpha_eq(b,astp) && 
                                         alpha_eq(c,ast1) ->
	(int_of_r_rec ast1 astp a)+1
    | a when alpha_eq(a,ast1) -> 1  
    | _ -> raise Non_closed_number
	  
let int_of_r p =
  let (_,ast1,astp,_) = get_r_sign dummy_loc in
  try 
    Some (int_of_r_rec ast1 astp p)
  with
    Non_closed_number -> None

let replace_plus p = 
  let (_,ast1,_,astnr) = get_r_sign dummy_loc in
     ope ("REXPR",[ope("APPLIST", [astnr; p; ast1;])]) 

let r_printer std_pr p =
 let (_,ast1,astp,_) = get_r_sign dummy_loc in
  match (int_of_r p) with
    | Some i -> [< 'sTR (string_of_int (i+1)) >]
    | None -> std_pr (replace_plus p)


let _ = Esyntax.Ppprim.add ("r_printer", r_printer)


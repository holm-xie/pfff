/*
(* Joust: a Java lexer, parser, and pretty-printer written in OCaml
 * Copyright (C) 2001  Eric C. Cooper <ecc@cmu.edu>
 * Released under the GNU General Public License
 *
 * LALR(1) (ocamlyacc) grammar for Java
 *
 * Attempts to conform to:
 * The Java Language Specification, Second Edition
 * - James Gosling, Bill Joy, Guy Steele, Gilad Bracha
 * 
 * Some modifications by Yoann Padioleau.
 *  - support annotations (partial)
 *  - support for generics (partial)
 *  - enums, foreach, ...
 *)
 */
%{
open Common
open Ast_java

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

(* todo? use a Ast.special? *)
let this_ident ii = ("this", ii)
let super_ident ii = ("super", ii)

let named_type (str, ii) = TBasic (str,ii)
let void_type ii = named_type ("void", ii)

(* we have to use a 'name' to specify reference types in the grammar
 * because of some ambiguity but what we really wanted was a 
 * identifier followed by some type arguments.
 *)
let reference_type name =
  raise Todo

type var_decl_id =
  | IdentDecl of ident
  | ArrayDecl of var_decl_id

(* Move array dimensions from variable name to type. *)
let rec canon_var mods t v =
  match v with
  | IdentDecl str -> { v_mods = mods; v_type = t; v_name = str }
  | ArrayDecl v' -> canon_var mods (ArrayType t) v'

let method_header mods mtype (v, formals) throws =
  { m_var = canon_var mods mtype v; m_formals = formals;
    m_throws = throws; m_body = Empty }

(* Return a list of field declarations in canonical form. *)

let decls f = fun mods vtype vars ->
  let dcl (v, init) =
    f { f_var = canon_var mods vtype v; f_init = init }
  in
  List.map dcl vars

let field_decls = decls (fun x -> Field x)
let var_decls   = decls (fun x -> LocalVar x)

let constructor_invocation name args =
  Expr (Call ((Name name), args))

%}

/*(*************************************************************************)*/
/*(*1 Tokens *)*/
/*(*************************************************************************)*/

/*(*-----------------------------------------*)*/
/*(*2 The comment tokens *)*/
/*(*-----------------------------------------*)*/
/*(* pad: those tokens are not even used in this file because they are
   * filtered in some intermediate phases. But they still must be declared
   * because ocamllex may generate them, or some intermediate phases may also
   * generate them (like some functions in parsing_hacks.ml)
   *)*/
%token <Ast_java.info> TComment TCommentNewline TCommentSpace 

/*(*-----------------------------------------*)*/
/*(*2 The normal tokens *)*/
/*(*-----------------------------------------*)*/

/*(* tokens with "values" *)*/
%token <string * Ast_java.info> TInt
%token <string * Ast_java.info> TFloat
%token <string * Ast_java.info> TChar
%token <string * Ast_java.info> TString

%token <(string * Ast_java.info)> LITERAL

%token <(string * Ast_java.info)> IDENTIFIER
%token <(string * Ast_java.info)> PRIMITIVE_TYPE

/*
 * 3.11 Separators
 */
%token <Ast_java.info> LP		/* ( */
%token <Ast_java.info> RP		/* ) */
%token <Ast_java.info> LC		/* { */
%token <Ast_java.info> RC		/* } */
%token <Ast_java.info> LB		/* [ */
%token <Ast_java.info> RB		/* ] */
%token <Ast_java.info> SM		/* ; */
%token <Ast_java.info> CM		/* , */
%token <Ast_java.info> DOT		/* . */

/*
 * 3.12 Operators
 */
%token <Ast_java.info> EQ		/* = */
%token <Ast_java.info> GT		/* > */
%token <Ast_java.info> LT		/* < */
%token <Ast_java.info> NOT		/* ! */
%token <Ast_java.info> COMPL		/* ~ */
%token <Ast_java.info> COND		/* ? */
%token <Ast_java.info> COLON		/* : */
%token <Ast_java.info> EQ_EQ		/* == */
%token <Ast_java.info> LE		/* <= */
%token <Ast_java.info> GE		/* >= */
%token <Ast_java.info> NOT_EQ		/* != */
%token <Ast_java.info> AND_AND		/* && */
%token <Ast_java.info> OR_OR		/* || */
%token <Ast_java.info> INCR		/* ++ */
%token <Ast_java.info> DECR		/* -- */
%token <Ast_java.info> PLUS		/* + */
%token <Ast_java.info> MINUS		/* - */
%token <Ast_java.info> TIMES		/* * */
%token <Ast_java.info> DIV		/* / */
%token <Ast_java.info> AND		/* & */
%token <Ast_java.info> OR		/* | */
%token <Ast_java.info> XOR		/* ^ */
%token <Ast_java.info> MOD		/* % */
%token <Ast_java.info> LS		/* << */
%token <Ast_java.info> SRS		/* >> */
%token <Ast_java.info> URS		/* >>> */

%token <Ast_java.info> AT		/* @ */
%token <Ast_java.info> DOTS		/* ... */

/*(* Those fresh tokens are created in parsing_hacks_java.ml *)*/
%token <Ast_java.info> LT2		/* < */

%token <(string * Ast_java.info)> OPERATOR_EQ	/* += -= *= /= &= |= ^= %= <<= >>= >>>= */

/*(* keywords tokens *)*/
/*
 * 3.9 Keywords
 */
%token <Ast_java.info> 
 ABSTRACT BOOLEAN BREAK BYTE CASE CATCH CHAR CLASS CONST CONTINUE
 DEFAULT DO DOUBLE ELSE EXTENDS FINAL FINALLY FLOAT FOR GOTO
 IF IMPLEMENTS IMPORT INSTANCEOF INT INTERFACE LONG
 NATIVE NEW PACKAGE PRIVATE PROTECTED PUBLIC RETURN
 SHORT STATIC STRICTFP SUPER SWITCH SYNCHRONIZED
 THIS THROW THROWS TRANSIENT TRY VOID VOLATILE WHILE 
 /*(* javaext: *)*/
 ASSERT
 ENUM

/*(*-----------------------------------------*)*/
/*(*2 Extra tokens: *)*/
/*(*-----------------------------------------*)*/

/*(* classic *)*/
%token <Ast_java.info> TUnknown
%token <Ast_java.info> EOF

/*(*************************************************************************)*/
/*(*1 Priorities *)*/
/*(*************************************************************************)*/

/*(*************************************************************************)*/
/*(*1 Rules type declaration *)*/
/*(*************************************************************************)*/
/*
(*
 * The start production must begin with a lowercase letter,
 * because ocamlyacc defines the parsing function with that name.
 *)
*/
%start goal
%type <Ast_java.program> goal

%type <Ast_java.typ> type_java
%type <Ast_java.stmt> statement
%type <Ast_java.expr> expression

%%

/*(*************************************************************************)*/
/*(*1 TOC *)*/
/*(*************************************************************************)*/
/*
(* TOC:
 *  goal
 *  name
 *  type
 *  expr
 *  statement
 *  declaration
 *  anotation
 *  class/interfaces
 *)
*/
/*(*************************************************************************)*/
/*(*1 Toplevel *)*/
/*(*************************************************************************)*/

goal: compilation_unit EOF  { $1 }

/* 7.3 */
compilation_unit: 
  package_declaration_opt import_declarations_opt type_declarations_opt
  { { package = $1; imports = $2; decls = $3; } }

/*(*************************************************************************)*/
/*(*1 Package, Import, Type *)*/
/*(*************************************************************************)*/

/* 7.4.1 */
package_declaration: PACKAGE name SM  { List.rev $2 }

/* 7.5 */
import_declaration:
 | IMPORT static_opt name SM  { $2, List.rev $3 }
 | IMPORT static_opt name DOT TIMES SM  
     { 
       (* todo: use special? *)
       let star_ident = ("*", $5) in
       $2, List.rev (star_ident :: $3) 
     }

/* 7.6 */
type_declaration:
 | class_declaration  { [Class $1] }
 | enum_declaration { ast_todo }
 | interface_declaration  { [Class $1] }
 | annotation_type_declaration { ast_todo }
 | SM  { [] }

/*(*************************************************************************)*/
/*(*1 Ident, namespace  *)*/
/*(*************************************************************************)*/
/* 3.8 */
identifier: IDENTIFIER  { $1 }

/* 6.5 */
name:
 | identifier_           { [$1] }
 | name DOT identifier_  { $3 :: $1 }
 | name DOT LT type_arguments GT identifier_  { $6 :: $1 }

identifier_:
 | identifier { $1 }
 | identifier LT2 type_arguments GT { $1 }

/*(*************************************************************************)*/
/*(*1 Types *)*/
/*(*************************************************************************)*/

/* 4.1 */
type_java:
 | primitive_type  { $1 }
 | reference_type  { $1 }
 | array_type   { $1 }

/* 4.2 */
primitive_type: PRIMITIVE_TYPE  { named_type $1 }

/* 4.3 */
reference_type:
 | name         { reference_type $1 }

class_or_interface_type: name  { List.rev $1 }

class_type: name             { List.rev $1 }
interface_type: name         { List.rev $1 }

array_type:
 | primitive_type LB RB { ArrayType $1 }
 | name           LB RB { ArrayType (reference_type (List.rev $1)) }
 | array_type     LB RB { ArrayType $1 }

/*(*----------------------------*)*/
/*(*2 Generics arguments *)*/
/*(*----------------------------*)*/

type_argument:
 | reference_type { }
 | COND { }
 | COND EXTENDS reference_type { }
 | COND SUPER reference_type { }

/*(*----------------------------*)*/
/*(*2 Generics parameters *)*/
/*(*----------------------------*)*/
type_parameter: 
 | identifier { }
 | identifier EXTENDS bound { }

bound:
 reference_type { }
/*(* todo: { & reference_type } *)*/

/*(*************************************************************************)*/
/*(*1 Expressions *)*/
/*(*************************************************************************)*/

/* 15.8 */
primary:
 | primary_no_new_array  { $1 }
 | array_creation_expression  { $1 }

primary_no_new_array:
 | literal             { $1 }
 | class_literal       { $1 }
 | THIS                { Name [this_ident $1] }
 | name DOT THIS       { Name (List.rev (this_ident $3 :: $1)) }
 | LP expression RP    { $2 }
 | class_instance_creation_expression { $1 }
 | field_access                       { $1 }
 | method_invocation                  { $1 }
 | array_access                       { $1 }

/* 3.10 */
literal: 
 | LITERAL { Literal ($1) }

 | TInt { Literal ($1) }
 | TFloat { Literal ($1) }
 | TChar { Literal ($1) }
 | TString { Literal ($1) }

/* 15.8.2 */
class_literal:
 | primitive_type DOT CLASS  { ClassLiteral $1 }
 | name           DOT CLASS  { ClassLiteral (reference_type (List.rev $1)) }
 | array_type     DOT CLASS  { ClassLiteral $1 }
 | VOID           DOT CLASS  { ClassLiteral (void_type $1) }

/* 15.9 */
class_instance_creation_expression:
 | NEW class_or_interface_type LP argument_list_opt RP class_body_opt
       { NewClass ((reference_type $2), $4, $6) }
 | primary DOT NEW identifier LP argument_list_opt RP class_body_opt
       { NewQualifiedClass ($1, $4, $6, $8) }
 /*(* not in 2nd edition java language specification. *)*/
 | name DOT NEW identifier LP argument_list_opt RP class_body_opt
       { NewQualifiedClass ((Name (List.rev $1)), $4, $6, $8) }

/* 15.10 */
array_creation_expression:
 | NEW primitive_type dim_exprs dims_opt
       { NewArray ($2, List.rev $3, $4, None) }
 | NEW name dim_exprs dims_opt
       { NewArray ((reference_type (List.rev $2)), List.rev $3, $4, None) }
 | NEW primitive_type dims array_initializer
       { NewArray ($2, [], $3, Some $4) }
 | NEW name dims array_initializer
       { NewArray ((reference_type (List.rev $2)), [], $3, Some $4) }


dim_expr: LB expression RB  { $2 (*TODO*) }

dims:
 | LB RB  { 1 (*TODO*) }
 | dims LB RB  { $1 + 1 (*TODO*) }


/* 15.11 */
field_access:
 | primary DOT identifier
	{ Dot ($1, $3) }
 | SUPER DOT identifier
	{ Name [super_ident $1; $3] }
 | name DOT SUPER DOT identifier
	{ Name (List.rev ($5 :: super_ident $3 :: $1)) }

/* 15.13 */
array_access:
 | name LB expression RB  { ArrayAccess ((Name (List.rev $1)), $3) }
 | primary_no_new_array LB expression RB  { ArrayAccess ($1, $3) }


/*(*----------------------------*)*/
/*(*2 Method call *)*/
/*(*----------------------------*)*/

/* 15.12 */
method_invocation:
 | name LP argument_list_opt RP  
        { Call ((Name (List.rev $1)), $3) }
 | primary DOT identifier LP argument_list_opt RP
	{ Call ((Dot ($1, $3)), $5) }
 | SUPER DOT identifier LP argument_list_opt RP
	{ Call ((Name [super_ident $1; $3]), $5) }
 | name DOT SUPER DOT identifier LP argument_list_opt RP
	{ Call ((Name (List.rev ($5 :: super_ident $3 :: $1))), $7)}

/*(*----------------------------*)*/
/*(*2 Arithmetic *)*/
/*(*----------------------------*)*/

/* 15.14 */
postfix_expression:
 | primary  { $1 }
 | name     { Name (List.rev $1) }
 | post_increment_expression  { $1 }
 | post_decrement_expression  { $1 }
 

/* 15.14.1 */
post_increment_expression: postfix_expression INCR  { Postfix ($1, "++") }

/* 15.14.2 */
post_decrement_expression: postfix_expression DECR  { Postfix ($1, "--") }

/* 15.15 */
unary_expression:
 | pre_increment_expression  { $1 }
 | pre_decrement_expression  { $1 }
 | PLUS unary_expression  { Prefix ("+", $2) }
 | MINUS unary_expression  { Prefix ("-", $2) }
 | unary_expression_not_plus_minus  { $1 }

pre_increment_expression: INCR unary_expression  { Prefix ("++", $2) }

pre_decrement_expression: DECR unary_expression  { Prefix ("--", $2) }

unary_expression_not_plus_minus:
 | postfix_expression  { $1 }
 | COMPL unary_expression  { Prefix ("~", $2) }
 | NOT unary_expression  { Prefix ("!", $2) }
 | cast_expression  { $1 }

/* 15.16 */

/*
(*
 *  original rule:
 * cast_expression:
 *	LP primitive_type dims_opt RP unary_expression
 * |	LP reference_type RP unary_expression_not_plus_minus
 *)
*/
/*
(*
 * modified (overly liberal) rule for LALR(1) grammar.
 * semantic action must ensure that '( expression )' is really '( name )'
 *)*/
cast_expression:
 | LP primitive_type RP unary_expression  { Cast ($2, $4) }
 | LP expression RP unary_expression_not_plus_minus
	{ 
          let typname = 
            match $2 with
            | Name name -> reference_type name
            | _ -> raise Parsing.Parse_error
          in
          Cast (typname, $4)
        }
 | LP array_type RP unary_expression_not_plus_minus  { Cast ($2, $4) }

/* 15.17 */
multiplicative_expression:
 | unary_expression  { $1 }
 | multiplicative_expression TIMES unary_expression
		{ Infix ($1, "*", $3) }
 | multiplicative_expression DIV unary_expression
		{ Infix ($1, "/", $3) }
 | multiplicative_expression MOD unary_expression
		{ Infix ($1, "%", $3) }


/* 15.18 */
additive_expression:
 | multiplicative_expression  
        { $1 }
 | additive_expression PLUS multiplicative_expression
	{ Infix ($1, "+", $3) }
 | additive_expression MINUS multiplicative_expression
	{ Infix ($1, "-", $3) }


/* 15.19 */
shift_expression:
 | additive_expression  { $1 }
 | shift_expression LS additive_expression  { Infix ($1, "<<", $3) }
 | shift_expression SRS additive_expression  { Infix ($1, ">>", $3) }
 | shift_expression URS additive_expression  { Infix ($1, ">>>", $3) }


/* 15.20 */
relational_expression:
 | shift_expression  { $1 }
 | relational_expression LT shift_expression  { Infix ($1, "<", $3) }
 | relational_expression GT shift_expression  { Infix ($1, ">", $3) }
 | relational_expression LE shift_expression  { Infix ($1, "<=", $3) }
 | relational_expression GE shift_expression  { Infix ($1, ">=", $3) }
 | relational_expression INSTANCEOF reference_type  { InstanceOf ($1, $3) }


/* 15.21 */
equality_expression:
 | relational_expression  
        { $1 }
 | equality_expression EQ_EQ relational_expression
	{ Infix ($1, "==", $3) }
 | equality_expression NOT_EQ relational_expression
	{ Infix ($1, "!=", $3) }


/* 15.22 */
and_expression:
 | equality_expression  { $1 }
 | and_expression AND equality_expression  { Infix ($1, "&", $3) }

exclusive_or_expression:
 | and_expression  { $1 }
 | exclusive_or_expression XOR and_expression  { Infix ($1, "^", $3) }


inclusive_or_expression:
 | exclusive_or_expression  { $1 }
 | inclusive_or_expression OR exclusive_or_expression  { Infix ($1, "|", $3) }

/* 15.23 */
conditional_and_expression:
 | inclusive_or_expression  { $1 }
 | conditional_and_expression AND_AND inclusive_or_expression
       { Infix ($1, "&&", $3) }


/* 15.24 */
conditional_or_expression:
 | conditional_and_expression  { $1 }
 | conditional_or_expression OR_OR conditional_and_expression
	{ Infix ($1, "||", $3) }

/*(*----------------------------*)*/
/*(*2 Ternary *)*/
/*(*----------------------------*)*/

/* 15.25 */
conditional_expression:
 | conditional_or_expression  { $1 }
 | conditional_or_expression COND expression COLON conditional_expression
	{ Conditional ($1, $3, $5) }

/*(*----------------------------*)*/
/*(*2 Assign *)*/
/*(*----------------------------*)*/

/* 15.26 */
assignment_expression:
 | conditional_expression  { $1 }
 | assignment  { $1 }

assignment: left_hand_side assignment_operator assignment_expression
    { Assignment ($1, fst $2, $3) }


left_hand_side:
 | name  { Name (List.rev $1) }
 | field_access  { $1 }
 | array_access  { $1 }

assignment_operator:
 | EQ  { "=", $1  }
 | OPERATOR_EQ  { $1 }


/*(*----------------------------*)*/
/*(*2 Shortcuts *)*/
/*(*----------------------------*)*/
/* 15.27 */
expression: assignment_expression  { $1 }

/* 15.28 */
constant_expression: expression  { $1 }

/*(*************************************************************************)*/
/*(*1 Statements *)*/
/*(*************************************************************************)*/

/* 14.5 */
statement:
 | statement_without_trailing_substatement  { $1 }

 | labeled_statement  { $1 }
 | if_then_statement  { $1 }
 | if_then_else_statement  { $1 }
 | while_statement  { $1 }
 | for_statement  { $1 }


statement_without_trailing_substatement:
 | block  { $1 }
 | empty_statement  { $1 }
 | expression_statement  { $1 }
 | switch_statement  { $1 }
 | do_statement  { $1 }
 | break_statement  { $1 }
 | continue_statement  { $1 }
 | return_statement  { $1 }
 | synchronized_statement  { $1 }
 | throw_statement  { $1 }
 | try_statement  { $1 }
 /*(* javaext:  *)*/
 | ASSERT expression SM { Assert ($2, None) }
 | ASSERT expression COLON expression SM { Assert ($2, Some $4) }

statement_no_short_if:
 | statement_without_trailing_substatement  { $1 }
 | labeled_statement_no_short_if  { $1 }
 | if_then_else_statement_no_short_if  { $1 }
 | while_statement_no_short_if  { $1 }
 | for_statement_no_short_if  { $1 }



/* 14.2 */
block: LC block_statements_opt RC  { Block $2 }

block_statement:
 | local_variable_declaration_statement  { $1 }
 | class_declaration  { [LocalClass $1] }
 | statement  { [$1] }

/* 14.4 */
local_variable_declaration_statement: local_variable_declaration SM  
 { $1 (* TODO *) }

/*(* cant factorize with variable_modifier_opt, conflicts otherwise *)*/
local_variable_declaration:
 | type_java variable_declarators  
     { let xs = var_decls [] $1 (List.rev $2) in
       xs +> List.map (fun x -> x)
     }
/*(* actually should be variable_modifiers but conflict *)*/
 | modifiers type_java variable_declarators  
   { [] }

/* 14.6 */
empty_statement: SM { Empty }

/* 14.7 */
labeled_statement: identifier COLON statement  
   { Label ($1, $3) }

labeled_statement_no_short_if: identifier COLON statement_no_short_if  
   { Label ($1, $3) }

/* 14.8 */
expression_statement: statement_expression SM  { Expr $1 }

/*(* pad: good *)*/
statement_expression:
 | assignment  { $1 }
 | pre_increment_expression  { $1 }
 | pre_decrement_expression  { $1 }
 | post_increment_expression  { $1 }
 | post_decrement_expression  { $1 }
 | method_invocation  { $1 }
 | class_instance_creation_expression  { $1 }



/* 14.9 */
if_then_statement: IF LP expression RP statement
   { If ($3, $5, None) }

if_then_else_statement: IF LP expression RP statement_no_short_if ELSE statement
   { If ($3, $5, Some $7) }

if_then_else_statement_no_short_if: 
 IF LP expression RP statement_no_short_if ELSE statement_no_short_if
   { If ($3, $5, Some $7) }


/* 14.10 */
switch_statement: SWITCH LP expression RP switch_block
    { Switch ($3, $5) }

switch_block:
 | LC RC  { [] (* TODO *) }
 | LC switch_labels RC  { [$2, []] }
 | LC switch_block_statement_groups RC  { List.rev $2 }
 | LC switch_block_statement_groups switch_labels RC
     { List.rev ((List.rev $3, []) :: $2) }

switch_block_statement_group: switch_labels block_statements  { List.rev $1, $2 }
switch_label:
 | CASE constant_expression COLON  { Case $2 }
 | DEFAULT COLON  { Default }


/* 14.11 */
while_statement:	WHILE LP expression RP statement
     { While ($3, $5) }

while_statement_no_short_if: WHILE LP expression RP statement_no_short_if
     { While ($3, $5) }


/* 14.12 */
do_statement: DO statement WHILE LP expression RP SM
      { Do ($2, $5) }


/*(*----------------------------*)*/
/*(*2 For *)*/
/*(*----------------------------*)*/

/* 14.13 */
for_statement: 
  FOR LP for_control RP statement
	{ For (ast_todo2, $5) }

for_statement_no_short_if: 
  FOR LP for_control RP statement_no_short_if
	{ For (ast_todo2, $5) }

for_control:
 | for_init_opt SM expression_opt SM for_update_opt { }
 | for_var_control { }

for_init: 
| statement_expression_list  { List.rev $1 }
| local_variable_declaration  { $1 }

for_update: statement_expression_list  { List.rev $1 }

for_var_control:
 | type_java variable_declarator_id for_var_control_rest { }
/*(* actually only FINAL is valid here, but cant because get shift/reduce
   * conflict otherwise because for_init can be a local_variable_decl
   *)*/
 | modifiers type_java variable_declarator_id for_var_control_rest { }

for_var_control_rest:
 | COLON expression { }

/*(*----------------------------*)*/
/*(*2 Other *)*/
/*(*----------------------------*)*/

/* 14.14 */
break_statement:	BREAK identifier_opt SM  { Break $2 }

/* 14.15 */
continue_statement: CONTINUE identifier_opt SM  { Continue $2 }

/* 14.16 */
return_statement: RETURN expression_opt SM  { Return $2 }


/* 14.18 */
synchronized_statement: SYNCHRONIZED LP expression RP block  
  { Sync ($3, $5) }


/* 14.17 */
throw_statement:	THROW expression SM  { Throw $2 }

/* 14.19 */
try_statement:
 | TRY block catches             { Try ($2, List.rev $3, None) }
 | TRY block catches_opt finally  { Try ($2, $3, Some $4) }

catch_clause:
 | CATCH LP formal_parameter RP block  { $3, $5 (* TODO*) }
 /*(* not in 2nd edition java language specification.*) */
 | CATCH LP formal_parameter RP empty_statement  { $3, $5 (* TODO*) }

finally: FINALLY block  { $2 (* TODO*) }

/*(*************************************************************************)*/
/*(*1 Declaration *)*/
/*(*************************************************************************)*/

/* 8.1.1 */
/* 8.3.1 */
/* 8.4.3 */
/* 8.8.3 */
/* 9.1.1 */
/* 9.3 */
/* 9.4 */

/*(*
 * to avoid shift/reduce conflicts, we accept all modifiers
 * in front of all declarations.  the ones not applicable to
 * a particular kind of declaration must be detected in semantic actions.
 *)*/

modifier:
 | PUBLIC       { Public, $1 }
 | PROTECTED    { Protected, $1 }
 | PRIVATE      { Private, $1 }

 | ABSTRACT     { Abstract, $1 }
 | STATIC       { Static, $1 }
 | FINAL        { Final, $1 }

 | STRICTFP     { StrictFP, $1 }
 | TRANSIENT    { Transient, $1 }
 | VOLATILE     { Volatile, $1 }
 | SYNCHRONIZED { Synchronized, $1 }
 | NATIVE       { Native, $1 }

 | annotation { Annotation, $1  }

/*(*************************************************************************)*/
/*(*1 Annotation *)*/
/*(*************************************************************************)*/

annotation: 
 | AT name { $1 }
 | AT name LP annotation_element_opt RP { $1 }

annotation_element:
 | element_value { }
 | element_value_pairs { }

element_value:
 | expr1 { }
 | annotation { }
 | element_value_array_initializer { }

element_value_pair:
 | identifier EQ element_value { }


element_value_array_initializer:
 | LC RC { }
 | LC element_values RC { }
 | LC element_values CM RC { }

expr1: 
 | primary_no_new_array { }
 | primary_no_new_array PLUS primary_no_new_array { }
 | name { } 

/*(*************************************************************************)*/
/*(*1 Class/Interface *)*/
/*(*************************************************************************)*/

/*(*----------------------------*)*/
/*(*2 Class *)*/
/*(*----------------------------*)*/
/* 8.1 */
class_declaration: 
 modifiers_opt CLASS identifier type_parameters_opt super_opt interfaces_opt
 class_body
  { { cl_mods = $1; cl_name = $3; cl_super = $5; 
      cl_impls = $6; cl_body = $7;
      cl_kind = ClassRegular;
     }
  }

/* 8.1.3 */
super: EXTENDS type_java  { $2 }

/* 8.1.4 */
interfaces: IMPLEMENTS interface_type_list  { List.rev $2 }


/*(*----------------------------*)*/
/*(*2 Class body *)*/
/*(*----------------------------*)*/
/* 8.1.5 */
class_body: LC class_body_declarations_opt RC  { $2 }

class_body_declaration:
 | class_member_declaration  { $1 }
 | constructor_declaration  { [$1] }

 | instance_initializer  { [$1] }
 | static_initializer  { [$1] }

class_member_declaration:
 | field_declaration  { $1 }
 | method_declaration  { [Method $1] }
 | generic_method_or_constructor_decl { [] }

 | class_declaration  { [Class $1] }
 | enum_declaration { ast_todo }
 | interface_declaration  { [Class $1] }
 | annotation_type_declaration { ast_todo }

 | SM  { [] }


/* 8.3 */
field_declaration: modifiers_opt type_java variable_declarators SM  
   { field_decls $1 $2 (List.rev $3) }


variable_declarator:
 | variable_declarator_id  { $1, None }
 | variable_declarator_id EQ variable_initializer  { $1, Some $3 }


variable_declarator_id:
 | identifier                  { IdentDecl $1 }
 | variable_declarator_id LB RB  { ArrayDecl $1 }


variable_initializer:
 | expression        { ExprInit $1 }
 | array_initializer  { $1 }

/* 10.6 */
array_initializer:
 | LC comma_opt RC  
     { ArrayInit [] }
 | LC variable_initializers comma_opt RC  
     { ArrayInit (List.rev $2) }


/* 8.4 */
method_declaration: method_header method_body  
  { let method_decl hdr body = { hdr with m_body = body } in
     method_decl $1 $2 
   }

method_header: 
 | modifiers_opt type_java method_declarator throws_opt
     { method_header $1 $2 $3 $4 }
 | modifiers_opt VOID method_declarator throws_opt
     { method_header $1 (void_type $2) $3 $4 }

method_declarator:
 | identifier LP formal_parameter_list_opt RP  { (IdentDecl $1), $3 }
 | method_declarator LB RB                   { (ArrayDecl (fst $1)), snd $1 }


generic_method_or_constructor_decl:
 | modifiers_opt type_parameters generic_method_or_constructor_rest  { }

generic_method_or_constructor_rest:
 | type_java identifier method_declarator_rest { }
 | VOID identifier method_declarator_rest { }

method_declarator_rest:
 | formal_parameters throws_opt method_body { }

formal_parameters: LP formal_parameter_list_opt RP { }

/* 8.4.4 */
throws: THROWS class_type_list  { List.rev $2 }

/* 8.4.5 */
method_body:
 | block  { $1 }
 | SM  { Empty }


/* 8.6 */
instance_initializer: block  { Init (false, $1) }
/* 8.7 */
static_initializer: STATIC block  { Init (true, $2) }

/* 8.8 */
constructor_declaration:	
 modifiers_opt constructor_declarator throws_opt constructor_body
  { 
    let no_type = TBasic ("void", fakeInfo "void") in
    let (id, formals) = $2 in
    let var = { v_mods = $1; v_type = no_type; v_name = id } in
    Method { m_var = var; m_formals = formals; m_throws = $3;
	     m_body = $4 }
  }

constructor_declarator:	identifier LP formal_parameter_list_opt RP  { $1, $3 }

/* 8.8.5 */
constructor_body:
 | LC block_statements_opt RC  
     { Block $2 }
 | LC explicit_constructor_invocation block_statements_opt RC
     { Block ($2 :: $3) }


/* 8.8.5.1 */
explicit_constructor_invocation:
 | THIS LP argument_list_opt RP SM
      { constructor_invocation [this_ident $1] $3 }
 | SUPER LP argument_list_opt RP SM
      { constructor_invocation [super_ident $1] $3 }
 | primary DOT SUPER LP argument_list_opt RP SM
      { 
        Expr (Call ((Dot ($1, super_ident $3)), $5))
      }
 /*(* not in 2nd edition java language specification. *)*/
 | name DOT SUPER LP argument_list_opt RP SM
      { constructor_invocation (List.rev (super_ident $3 :: $1)) $5 }

/*(*----------------------------*)*/
/*(*2 Method parameter *)*/
/*(*----------------------------*)*/

/* 8.4.1 */
formal_parameter: variable_modifiers_opt type_java variable_declarator_id_bis
  { 
    let formal_decl mods t v = canon_var mods t v in
    (* todo: use $1 *)
    formal_decl [] $2 $3 
  }

variable_declarator_id_bis:
 | variable_declarator_id { $1 }
 | DOTS variable_declarator_id { $2 (* todo_ast *) }

variable_modifier:
 | FINAL { }
 | annotation { }

/*(*----------------------------*)*/
/*(*2 Interface *)*/
/*(*----------------------------*)*/

/* 9.1 */
interface_declaration: 
 modifiers_opt INTERFACE identifier type_parameters_opt  extends_interfaces_opt 
 interface_body
  { { cl_mods = $1; cl_name = $3; cl_super = None;
      cl_impls = $5; cl_body = $6;
      cl_kind = Interface;
    } 
  }

/* 9.1.2 */
extends_interfaces:
 | EXTENDS interface_type  { [$2] }
 | extends_interfaces CM interface_type  { $3 :: $1 }

/*(*----------------------------*)*/
/*(*2 Interface body *)*/
/*(*----------------------------*)*/
/* 9.1.3 */
interface_body:	LC interface_member_declarations_opt RC  { $2 }

interface_member_declaration:
 | constant_declaration  { $1 }
 | abstract_method_declaration  { [Method $1] }
 | interface_generic_method_decl { [] }

 | class_declaration  { [Class $1] }
 | interface_declaration  { [Class $1] }
 | annotation_type_declaration { ast_todo }
 | enum_declaration  { [] }
 | SM  { [] }

/* 9.3 */

/*(* note: semicolon is missing in 2nd edition java language specification.*)*/
constant_declaration: modifiers_opt type_java variable_declarators SM
     { field_decls $1 $2 (List.rev $3) }

/* 9.4 */
abstract_method_declaration:
 | modifiers_opt type_java method_declarator throws_opt SM
	{ method_header $1 $2 $3 $4 }
 | modifiers_opt VOID method_declarator throws_opt SM
	{ method_header $1 (void_type $2) $3 $4 }

interface_generic_method_decl:
 | modifiers_opt type_parameters type_java identifier interface_method_declator_rest 
    { }
 | modifiers_opt type_parameters VOID identifier interface_method_declator_rest 
    { }

interface_method_declator_rest:
 | formal_parameters throws_opt SM { }

/*(*----------------------------*)*/
/*(*2 Enum *)*/
/*(*----------------------------*)*/
enum_declaration: modifiers_opt ENUM identifier interfaces_opt enum_body 
 { }

/*(* cant factorize in enum_constants_opt comma_opt .... *)*/
enum_body: 
 | LC                   enum_body_declarations_opt RC { }
 | LC enum_constants    enum_body_declarations_opt RC { }
 | LC enum_constants CM enum_body_declarations_opt RC { }

enum_constant:
 | identifier { }
 | identifier LP argument_list_opt RP { }

enum_body_declarations: SM class_body_declarations_opt { }

/*(*----------------------------*)*/
/*(*2 Annotation type decl *)*/
/*(*----------------------------*)*/

/*(* cant factorize modifiers_opt *)*/
annotation_type_declaration: 
 | modifiers AT INTERFACE identifier annotation_type_body { }
 |           AT INTERFACE identifier annotation_type_body { }

annotation_type_body: LC annotation_type_element_declarations_opt RC { }

annotation_type_element_declaration:
 annotation_type_element_rest { }

annotation_type_element_rest:
 | modifiers_opt type_java identifier annotation_method_or_constant_rest SM { }

 | class_declaration { }
 | enum_declaration { }
 | interface_declaration { }
 | annotation_type_declaration {  }


annotation_method_or_constant_rest:
 | LP RP { }
 | LP RP DEFAULT element_value { }

annotation_type_element_declarations_opt:
 | { }
 | annotation_type_element_declarations { }

annotation_type_element_declarations:
 | annotation_type_element_declaration { }
 | annotation_type_element_declarations annotation_type_element_declaration { }

/*(*************************************************************************)*/
/*(*1 xxx_list, xxx_opt *)*/
/*(*************************************************************************)*/

import_declarations:
 | import_declaration  { [$1] }
 | import_declarations import_declaration  { $2 :: $1 }

import_declarations_opt:
 | /*(*empty*)*/  { [] }
 | import_declarations  { List.rev $1 }



type_declarations:
 | type_declaration  { $1 }
 | type_declarations type_declaration  { $1 @ $2 }

type_declarations_opt:
 | /*(*empty*)*/  { [] }
 | type_declarations  { $1 }



package_declaration_opt:
 | /*(*empty*)*/  { None }
 | package_declaration  { Some $1 }


modifiers:
 | modifier  { [$1] }
 | modifiers modifier  { $2 :: $1 }

modifiers_opt:
 | /*(*empty*)*/  { [] }
 | modifiers  { List.rev $1 }


super_opt:
 | /*(*empty*)*/  { None }
 | super  { Some $1 }


interfaces_opt:
 | /*(*empty*)*/  { [] }
 | interfaces  { $1 }


interface_type_list:
 | interface_type  { [$1] }
 | interface_type_list CM interface_type  { $3 :: $1 }


class_body_declarations:
 | class_body_declaration  { $1 }
 | class_body_declarations class_body_declaration  { $1 @ $2 }

class_body_declarations_opt:
 | /*(*empty*)*/  { [] }
 | class_body_declarations  { $1 }


variable_declarators:
 | variable_declarator  { [$1] }
 | variable_declarators CM variable_declarator  { $3 :: $1 }


formal_parameter_list:
 | formal_parameter  { [$1] }
 | formal_parameter_list CM formal_parameter  { $3 :: $1 }

formal_parameter_list_opt:
 | /*(*empty*)*/  { [] }
 | formal_parameter_list  { List.rev $1 }


variable_modifiers_opt:
 | /*(*empty*)*/  { None }
 | variable_modifiers  { Some $1 }

variable_modifiers:
 | variable_modifier { }
 | variable_modifiers variable_modifier { }

static_opt:
 | /*(*empty*)*/  { false }
 | STATIC  { true }

throws_opt:
 | /*(*empty*)*/  { [] }
 | throws  { $1 }

class_type_list:
 | class_type  { [$1] }
 | class_type_list CM class_type  { $3 :: $1 }


extends_interfaces_opt:
 | /*(*empty*)*/  { [] }
 | extends_interfaces  { List.rev $1 }


interface_member_declarations:
 | interface_member_declaration  { $1 }
 | interface_member_declarations interface_member_declaration  { $1 @ $2 }

interface_member_declarations_opt:
 | /*(*empty*)*/  { [] }
 | interface_member_declarations  { $1 }


variable_initializers:
 | variable_initializer  { [$1] }
 | variable_initializers CM variable_initializer  { $3 :: $1 }

comma_opt:
 | /*(*empty*)*/  { () }
 | CM  { () }


block_statements:
 | block_statement  { $1 }
 | block_statements block_statement  { $1 @ $2 }

block_statements_opt:
 | /*(*empty*)*/  { [] }
 | block_statements  { $1 }


switch_block_statement_groups:
 | switch_block_statement_group  { [$1] }
 | switch_block_statement_groups switch_block_statement_group  { $2 :: $1 }


switch_labels:
 | switch_label  { [$1] }
 | switch_labels switch_label  { $2 :: $1 }

for_init_opt:
 | /*(*empty*)*/  { [] }
 | for_init  { $1 }


expression_opt:
 | /*(*empty*)*/  { None }
 | expression  { Some $1 }


for_update_opt:
 | /*(*empty*)*/  { [] }
 | for_update  { $1 }

statement_expression_list:
 | statement_expression  { [Expr $1] }
 | statement_expression_list CM statement_expression  
     { (Expr $3) :: $1 }


identifier_opt:
 | /*(*empty*)*/  { None }
 | identifier  { Some $1 }


catches:
 | catch_clause  { [$1] }
 | catches catch_clause  { $2 :: $1 }

catches_opt:
 | /*(*empty*)*/  { [] }
 | catches  { List.rev $1 }


argument_list:
 | expression  { [$1] }
 | argument_list CM expression  { $3 :: $1 }

argument_list_opt:
 | /*(*empty*)*/  { [] }
 | argument_list  { List.rev $1 }


class_body_opt:
 | /*(*empty*)*/  { None }
 | class_body  { Some $1 }

dim_exprs:
 | dim_expr  { [$1] }
 | dim_exprs dim_expr  { $2 :: $1 }

dims_opt:
 | /*(*empty*)*/  { 0 }
 | dims  { $1 }


enum_constants:
 | enum_constant { }
 | enum_constants CM enum_constant { }

enum_body_declarations_opt: 
 | /*(*empty*)*/  {  }
 | enum_body_declarations  { }

type_parameters_opt:
 | /*(*empty*)*/   { [] }
 | type_parameters { $1 }

type_parameters:
 | LT type_parameters_bis GT { $2 }

type_parameters_bis: 
 | type_parameter  { [$1] }
 | type_parameters_bis CM type_parameter  { $1 ++ [$3] }


type_arguments:
 | type_argument  { [$1] }
 | type_arguments CM type_argument  { $1 ++ [$3] }

element_value_pairs: 
 | element_value_pair { [$1] }
 | element_value_pairs CM element_value_pair { $1 ++ [$3] }

annotation_element_opt:
 | /*(*empty*)*/ { None }
 | annotation_element { Some $1 }


element_values:
 | element_value { }
 | element_values CM element_value { }


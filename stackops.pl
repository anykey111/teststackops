:- use_module(library(lists)).
:- use_module(library(apply)).

op_cost(drop, 1).
op_cost(nip, 3).
op_cost(dup, 1).
op_cost(over, 3).
op_cost(third, 6).
op_cost(fourth, 8).
op_cost(tuck, 3).
op_cost(swap, 2).
op_cost(rot, 3).
op_cost(nop, 0).
op_cost(pick(I), N) :- N is I * 2.
op_cost(poll(I), N) :- N is I * 3.
op_cost(N, 1) :- number(N).
op_cost(_, 3).

ds_eval(drop, [_A|T], T).
ds_eval(nip, [A,_B|T], [A|T]).
ds_eval(dup, [A|T], [A,A|T]).
ds_eval(over, [A,B|T], [B,A,B|T]). 
ds_eval(third, [A,B,C|T], [C,A,B,C|T]).
ds_eval(fourth, [A,B,C,D|T], [D,A,B,C,D|T]).
ds_eval(tuck, [A,B|T], [A,B,A|T]).
ds_eval(swap, [A,B|T], [B,A|T]).
ds_eval(rot, [A,B,C|T], [C,A,B|T]).
ds_eval(pick(I), Stack, [Elem|Stack]) :-
    length(Stack, Len),
    between(5, Len, I),
    I < Len,
    nth0(I, Stack, Elem).
ds_eval(roll(I), Stack, [Elem|Rest]) :-
    length(Stack, Len),
    between(3, Len, I),
    I < Len,
    nth0(I, Stack, Elem, Rest).

moving_op(rot).
moving_op(swap).
moving_op(roll(_)).

ds_solve([], S, S).
ds_solve(Ops, Source, Result) :-
    (
        ds_eval(Op, Source, Result),
        Ops = [Op]
    ;
        moving_op(Op1),
        ds_eval(Op1, Source, Temp),
        ds_eval(Op2, Temp, Result),
        Ops = [Op2,Op1]
    ).

copy_named(State0, Name, 0, State_out) :-
    Stack1 = [Name|State0.stack],
    ds_solve(Ops1, State0.stack, Stack1), 
    append(Ops1, State0.ops, Ops),
    State_out = State0.put(ops, Ops).put(stack, Stack1).

copy_named(State0, Name, 1, State_out) :-
    [H|T] = State0.stack,
    Stack1 = [H,Name|T],
    ds_solve(Ops1, State0.stack, Stack1),
    append(Ops1, State0.ops, Ops),
    State_out = State0.put(ops, Ops).put(stack, Stack1).

move_named(State0, Name, Index, State_out) :-
    nth0(I, State0.stack, Name, Rest),
    (
        I =:= Index
    ->
        State_out = State0
    ;
        Stack1 = [Name|Rest],
        moving_op(Op),
        ds_eval(Op, State0.stack, Stack1),
        State_out = State0.put(stack, Stack1).put(ops, [Op|State0.ops])
    ).

fetch_var(State0, Name, Index, State_out) :-
    NumRefs = State0.refs.get(Name, 0),
    (
        NumRefs < 1
    ->
        move_named(State0, Name, Index, State_out)
    ;
        Counter is NumRefs - 1,
        Refs = State0.refs.put(Name, Counter),
        copy_named(State0.put(refs, Refs), Name, Index, State_out)
    ).

fetch_pair(State0, L, R, State_out) :-
    LCounter = State0.refs.get(L, 0),
    ( LCounter < 1
        -> select(L, State0.stack, Rest0)
        ; Rest0 = State0.stack
    ),
    RCounter = State0.refs.get(R, 0),
    ( RCounter < 1
        -> select(R, Rest0, Rest)
        ; Rest = Rest0
    ),
    Result = [R,L|Rest],
    ds_solve(Ops1, State0.stack, Result),
    append(Ops1, State0.ops, Ops),
    LCounterSub1 is LCounter - 1,
    RCounterSub1 is RCounter - 1,
    Refs = State0.refs.put(L, LCounterSub1).put(R, RCounterSub1),
    State_out = State0.put(refs, Refs).put(ops, Ops).put(stack, Result).

tr_expr(State0, bin('=',L,R), State_out, RTmp) :-
    assertion(L =.. [var,Name]),
    L =.. [var,Name],
    tr_expr(State0, R, State_out, RTmp),
    assertion(Name == RTmp).
tr_expr(State0, bin(Op,var(L),var(R)), State_out, Tmp) :-
    fetch_pair(State0, L, R, State1),
    [R,L|Rest] = State1.stack,
    atom_concat(L, R, Prefix),
    atom_concat(Prefix, Op, Tmp),
    State_out = State1.put(stack, [Tmp|Rest]).put(ops, [Op|State1.ops]).
tr_expr(State0, bin(Op,var(L),R), State_out, Tmp) :-
    R =.. [bin|_],
    tr_expr(State0, R, State1, RTmp),
    tr_expr(State1, bin(Op,var(L),var(RTmp)), State_out, Tmp).
tr_expr(State0, bin(Op,L,R), State_out, Tmp) :-
    tr_expr(State0, L, State1, LTmp),
    tr_expr(State1, R, State2, RTmp),
    [RTmp,LTmp|Rest] = State2.stack,
    atom_concat(LTmp, RTmp, Prefix),
    atom_concat(Prefix, Op, Tmp),
    State_out = State2.put(stack, [Tmp|Rest]).put(ops, [Op|State2.ops]).
tr_expr(State0, var(Name), State_out, Name) :-
    fetch_var(State0, Name, 0, State_out).
tr_expr(State0, num(Value), State_out, Value) :-
    State_out = State0.put(stack, [Value|State0.stack]).put(ops, [Value|State0.ops]).

gen_expr(Stack, Expr, Result) :-
    expr_ast(Expr, Ast0),
    fold_common_subexpr(Ast0, Ast),
    count_named_refs(Ast, Refs),
    tr_expr(state{stack:Stack, ops:[], refs:Refs}, Ast, State0, _Tmp),
    convlist(op_cost, State0.ops, TmpLs),
    sum_list(TmpLs, Total),
    reverse(State0.ops, OpsList),
    Result = (Total, OpsList).

expr_ast(Expr, bin(Op,L,R)) :-
    Expr =.. [Op, Left, Right],
    expr_ast(Left, L),
    expr_ast(Right, R).
expr_ast(Expr, var(Expr)) :-
    atom(Expr).
expr_ast(Expr, num(Expr)) :-
    number(Expr).

fold_common_subexpr(Ast0, Ast) :-
    fold_common_subexpr_(Ast0, Ast, refs{}, _).
fold_common_subexpr_(bin(Op,var(L),var(R)), Out, Refs0, Refs) :-
    atom_concat(L, R, Prefix),
    atom_concat(Prefix, Op, Tmp),
    N = Refs0.get(Tmp, -1),
    N1 is N + 1,
    Refs = Refs0.put(Tmp, N1),
    (
        N < 0
    ->
        Out = bin('=', var(Tmp), bin(Op,var(L),var(R)))
    ;
        Out = var(Tmp)
    ).
fold_common_subexpr_(bin(Op,L,R), bin(Op,L_out,R_out), Refs0, Refs) :-
    fold_common_subexpr_(L, L_out, Refs0, Refs1),
    fold_common_subexpr_(R, R_out, Refs1, Refs).
fold_common_subexpr_(Expr, Expr, Refs, Refs).

count_named_refs(Ast, Refs) :-
    count_named_refs_(Ast, refs{}, Refs).

count_named_refs_(num(_), Refs0, Refs0).
count_named_refs_(var(Name), Refs0, Refs_out) :-
    N = Refs0.get(Name, -1),
    N1 is N + 1,
    Refs_out = Refs0.put(Name, N1).
count_named_refs_(bin(_,L,R), Refs0, Refs_out) :-
    count_named_refs_(L, Refs0, Refs1),
    count_named_refs_(R, Refs1, Refs_out).

take_n([], _, Acc, Res) :- reverse(Acc, Res).
take_n(_, 0, Acc, Res) :- reverse(Acc, Res).
take_n([H|T], N, Acc, Res) :-
    N1 is N - 1,
    take_n(T, N1, [H|Acc], Res).

juggle(Stack,Expr,Result) :-
    setof(Result, gen_expr(Stack, Expr, Result), Bag),
    take_n(Bag, 25, [], Top),
    maplist(writeln, Top).


:- begin_tests(user).

test(cse1, []) :-
    once(gen_expr([a], a*a+a*a, X)),
    assertion(X == [+, dup, *, dup]).

test(cse2, []) :-
    once(gen_expr([a,b], a*b+a*b, X)),
    assertion(X == [+, dup, *, swap]).

test(cse3, []) :-
    once(gen_expr([a,b,c], a*b+c+a*b, X)),
    assertion(X == [+, swap, +, rot, dup, *, swap]).

test(r_first, []) :-
    once(gen_expr([a,b], a+b*a, X)),
    assertion(X == [+, *, tuck]).

test(preshufle, []) :-
    once(gen_expr([b,a], a+b*a, X)),
    assertion(X == [+, *, over]).

test(numbers, []) :-
    once(gen_expr([b,a], a+b*a-1, X)),
    assertion(X == [-, 1, +, *, over]).

:- end_tests(user).

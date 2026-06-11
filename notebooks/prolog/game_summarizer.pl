:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Request, ExpertStatus, Forbidden, Turn)
% Request: atom (or 'none'), ExpertStatus: true/false, Forbidden: true/false, Turn: user|expert

initial_state(state(none, true, false, user)).

current_player(state(_,_,_,P), P).

legal_move(state(_,_,_,user), user_input(Input)).
legal_move(state(Req,_,_,expert), expert_summary) :- Req \= none.

apply_move(state(Req, Exp, Forb, user), user_input(Input),
           state(NewReq, Exp, NewForb, expert)) :-
    \+ var(Input),
    Input \= '',
    ( Input = 'chocolate cake recipe'
        -> NewReq = Req, NewForb = true
    ;  NewReq = Input, NewForb = Forb
    ).

apply_move(state(Req, Exp, Forb, expert), expert_summary,
           state(Req, false, Forb, user)) :-
    Req \= none.

game_over(state(Req, Exp, Forb, _), Winner) :-
    ( Forb = true -> Winner = draw
    ; Exp = false, Req \= none -> Winner = expert
    ).

render_state(state(Req, Exp, Forb, Turn)) :-
    format("Current Request: ~w~nExpert Status: ~w~nForbidden Topic Triggered: ~w~nTurn: ~w~n",
           [Req, Exp, Forb, Turn]).

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, user_input(chess), S2), render_state(S2).
% ?- initial_state(S), apply_move(S, user_input('chocolate cake recipe'), S2), apply_move(S2, expert_summary, S3), game_over(S3, W).
% ?- initial_state(S), apply_move(S, user_input(go), S2), apply_move(S2, expert_summary, S3), game_over(S3, W).
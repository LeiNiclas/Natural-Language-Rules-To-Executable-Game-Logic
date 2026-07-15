:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board helpers
set_nth1(1,[_|T],V,[V|T]).
set_nth1(N,[H|T],V,[H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1,T,V,R).

set_cell(Row,Col,Board,Value,NewBoard) :-
    nth1(Row,Board,OldRow),
    set_nth1(Col,OldRow,Value,NewRow),
    set_nth1(Row,Board,NewRow,NewBoard).

% state(Board,Turn,CastlingRights,EnPassantTarget,HalfmoveClock,FullmoveNumber)
initial_state(state([
  [black_rook,black_knight,black_bishop,black_queen,black_king,black_bishop,black_knight,black_rook],
  [black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn,black_pawn],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn,white_pawn],
  [white_rook,white_knight,white_bishop,white_queen,white_king,white_bishop,white_knight,white_rook]
], white,
  [white_kingside,white_queenside,black_kingside,black_queenside],
  null, 0, 1)).

current_player(state(_,Turn,_,_,_,_),Turn).

legal_move(State,resign(P)) :-
    current_player(State,P).

apply_move(state(B,T,CR,EP,HC,FN), resign(T),
           state(B,T,CR,EP,HC,FN)).

game_over(_,_) :- fail.

render_state(state(Board,_,_,_,_,_)) :-
    forall(nth1(_,Board,Row),
           ( forall(nth1(_,Row,Cell),
                    ( Cell = empty       -> format('. ')
                    ; Cell = white_king   -> format('K ')
                    ; Cell = white_queen  -> format('Q ')
                    ; Cell = white_rook   -> format('R ')
                    ; Cell = white_bishop -> format('B ')
                    ; Cell = white_knight -> format('N ')
                    ; Cell = white_pawn   -> format('P ')
                    ; Cell = black_king   -> format('k ')
                    ; Cell = black_queen  -> format('q ')
                    ; Cell = black_rook   -> format('r ')
                    ; Cell = black_bishop -> format('b ')
                    ; Cell = black_knight -> format('n ')
                    ; Cell = black_pawn   -> format('p ')
                    ; format('? ')
                    )
                  ),
             format('\n')
           )
    ).
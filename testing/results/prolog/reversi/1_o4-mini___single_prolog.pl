:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: Board is a list of 8 rows, each a list of 8 cells (empty|black|white); state(Board, CurrentPlayer).

% 2D board helpers
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Directions for capture checks
direction(-1, -1).
direction(-1, 0).
direction(-1, 1).
direction(0, -1).
direction(0, 1).
direction(1, -1).
direction(1, 0).
direction(1, 1).

% Board bounds check
in_bounds(Row, Col) :-
    Row >= 1, Row =< 8,
    Col >= 1, Col =< 8.

% Player opposites
opponent(black, white).
opponent(white, black).

% Capture in a given direction
capture_dir(Board, P, Row, Col, DR, DC, PosList) :-
    opponent(P, OP),
    R1 is Row+DR, C1 is Col+DC,
    in_bounds(R1, C1),
    nth1(R1, Board, Row1), nth1(C1, Row1, OP),
    gather(Board, P, R1, C1, DR, DC, [(R1,C1)], PosList).

gather(Board, P, Row, Col, DR, DC, Acc, PosList) :-
    R2 is Row+DR, C2 is Col+DC,
    in_bounds(R2, C2),
    nth1(R2, Board, Row2), nth1(C2, Row2, Cell),
    ( Cell = P ->
        PosList = Acc
    ; Cell \= empty,
      opponent(P, OP), Cell = OP ->
        gather(Board, P, R2, C2, DR, DC, [(R2,C2)|Acc], PosList)
    ).

% All positions to flip for a move
flippable(state(Board, P), Row, Col, Flips) :-
    findall(PosList,
            ( direction(DR, DC),
              capture_dir(Board, P, Row, Col, DR, DC, PosList)
            ),
            Lists),
    Lists \= [],
    flatten(Lists, Flips).

% Initial game state
initial_state(state(
    [
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,white,black,empty,empty,empty],
      [empty,empty,empty,black,white,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty]
    ],
    black
)).

% Current player to move
current_player(state(_, P), P).

% Legal place moves
legal_move(State, place(Row, Col)) :-
    State = state(Board, P),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    flippable(State, Row, Col, _).

% Legal pass move when no place moves exist
legal_move(State, pass) :-
    State = state(Board, P),
    \+ legal_move(state(Board, P), place(_, _)).

% Apply place move
apply_move(state(Board, P), place(Row, Col), state(NewBoard, P2)) :-
    flippable(state(Board, P), Row, Col, Flips),
    set_cell(Row, Col, Board, P, Board1),
    flip_positions(P, Flips, Board1, NewBoard),
    opponent(P, P2).

flip_positions(_, [], Board, Board).
flip_positions(P, [(R,C)|T], Board, NewBoard) :-
    set_cell(R, C, Board, P, Board1),
    flip_positions(P, T, Board1, NewBoard).

% Apply pass move
apply_move(state(Board, P), pass, state(Board, P2)) :-
    \+ legal_move(state(Board, P), place(_, _)),
    opponent(P, P2).

% Game over detection and winner determination
game_over(state(Board, _), Winner) :-
    ( \+ ( nth1(_, Board, Row), nth1(_, Row, empty) )
    ; ( \+ legal_move(state(Board, black), place(_, _)),
        \+ legal_move(state(Board, white), place(_, _))
      )
    ),
    findall(1, ( member(Row, Board), member(black, Row) ), Bs),
    length(Bs, Nb),
    findall(1, ( member(Row, Board), member(white, Row) ), Ws),
    length(Ws, Nw),
    ( Nb > Nw -> Winner = black
    ; Nw > Nb -> Winner = white
    ; Winner = draw
    ).

% Render the board to stdout
render_state(state(Board, _)) :-
    forall(nth1(_, Board, Row),
           ( forall(nth1(_, Row, C),
                    ( C = empty -> format('. ')
                    ; C = black -> format('B ')
                    ; C = white -> format('W ')
                    )
                  ),
             format('~n')
           )).
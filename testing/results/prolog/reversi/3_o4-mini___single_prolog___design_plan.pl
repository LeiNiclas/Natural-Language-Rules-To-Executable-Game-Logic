:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Board, Value, NewBoard)
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% valid_position(Row, Col)
valid_position(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% opponent(Player, Opponent)
opponent(black, white).
opponent(white, black).

% initial_state(State)
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

% current_player(State, Player)
current_player(state(_, Player), Player).

% get_cell(Board, Row, Col, Cell)
get_cell(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

% find_flips(Board, Row, Col, Player, Flips)
find_flips(Board, Row, Col, Player, Flips) :-
    Directions = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)],
    findall(FL,
        ( member((DR,DC), Directions),
          check_direction(Board,Row,Col,DR,DC,Player,FL)
        ),
        Lists),
    append(Lists, Flips).

% check_direction(Board, Row, Col, ΔRow, ΔCol, Player, ToFlip)
check_direction(Board, Row, Col, DR, DC, Player, ToFlip) :-
    R1 is Row+DR, C1 is Col+DC,
    valid_position(R1, C1),
    opponent(Player, Opp),
    get_cell(Board, R1, C1, Opp),
    check_sequence(Board, R1, C1, DR, DC, Player, [(R1,C1)], Rev),
    Rev \= [],
    reverse(Rev, ToFlip).

% check_sequence(Board, R, C, ΔR, ΔC, Player, Acc, ToFlip)
check_sequence(Board, R, C, DR, DC, Player, Acc, Acc) :-
    R2 is R+DR, C2 is C+DC,
    valid_position(R2, C2),
    get_cell(Board, R2, C2, Player).
check_sequence(Board, R, C, DR, DC, Player, Acc, ToFlip) :-
    R2 is R+DR, C2 is C+DC,
    valid_position(R2, C2),
    opponent(Player, Opp),
    get_cell(Board, R2, C2, Opp),
    check_sequence(Board, R2, C2, DR, DC, Player, [(R2,C2)|Acc], ToFlip).

% any_place_move(Board, Player)
any_place_move(Board, Player) :-
    between(1,8,Row),
    between(1,8,Col),
    get_cell(Board, Row, Col, empty),
    find_flips(Board, Row, Col, Player, Flips),
    Flips \= [].

% legal_move(State, place(Row, Col))
legal_move(state(Board, Player), place(Row, Col)) :-
    valid_position(Row, Col),
    get_cell(Board, Row, Col, empty),
    find_flips(Board, Row, Col, Player, Flips),
    Flips \= [].

% legal_move(State, pass)
legal_move(state(Board, Player), pass) :-
    \+ any_place_move(Board, Player).

% apply_flips(Board, Positions, Player, NewBoard)
apply_flips(Board, [], _, Board).
apply_flips(Board, [(R,C)|T], Player, NewBoard) :-
    set_cell(R, C, Board, Player, B1),
    apply_flips(B1, T, Player, NewBoard).

% apply_move(State, place(Row, Col), NewState)
apply_move(state(Board, Player), place(Row, Col), state(Board3, Next)) :-
    find_flips(Board, Row, Col, Player, Flips),
    set_cell(Row, Col, Board, Player, B1),
    apply_flips(B1, Flips, Player, B2),
    opponent(Player, Next),
    Board3 = B2.

% apply_move(State, pass, NewState)
apply_move(state(Board, Player), pass, state(Board, Next)) :-
    opponent(Player, Next).

% count_pieces(Board, Player, Count)
count_pieces(Board, Player, Count) :-
    append(Board, Flat),
    include(==(Player), Flat, L),
    length(L, Count).

% board_full(Board)
board_full(Board) :-
    \+ ( member(Row, Board), member(empty, Row) ).

% game_over(State, Winner)
game_over(state(Board, _), Winner) :-
    ( board_full(Board)
    ; \+ any_place_move(Board, black), \+ any_place_move(Board, white)
    ),
    count_pieces(Board, black, Bc),
    count_pieces(Board, white, Wc),
    ( Bc > Wc -> Winner = black
    ; Wc > Bc -> Winner = white
    ; Bc =:= Wc -> Winner = draw
    ).

% render_state(State)
render_state(state(Board, _)) :-
    maplist(render_row, Board).

% render_row(Row)
render_row(Row) :-
    maplist(render_cell, Row),
    format("~n", []).

% render_cell(Cell)
render_cell(empty)  :- format(". ", []).
render_cell(black)  :- format("B ", []).
render_cell(white)  :- format("W ", []).
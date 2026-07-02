:- use_module(library(lists)).
:- use_module(library(apply)).

% Reversi implementation using 2D board representation.
% Board is a list of 8 rows, each row is a list of 8 cells.
% Cells are atoms: black, white, empty.
% State is state(Board, CurrentPlayer).

% Helper to set a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state: 8x8 board with center pieces set
initial_state(state(Board, black)) :-
    EmptyRow = [empty, empty, empty, empty, empty, empty, empty, empty],
    Board0 = [EmptyRow, EmptyRow, EmptyRow, EmptyRow,
              EmptyRow, EmptyRow, EmptyRow, EmptyRow],
    set_cell(4, 4, Board0, white, B1),
    set_cell(4, 5, B1, black, B2),
    set_cell(5, 4, B2, black, B3),
    set_cell(5, 5, B3, white, Board).

% Current player in the state
current_player(state(_, P), P).

% Legal moves: either place or pass
legal_move(State, place(Row, Col)) :-
    State = state(Board, Player),
    between(1, 8, Row),
    between(1, 8, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    would_flip(Board, Row, Col, Player).

legal_move(State, pass) :-
    State = state(Board, Player),
    \+ (between(1, 8, Row),
        between(1, 8, Col),
        nth1(Row, Board, RowList),
        nth1(Col, RowList, empty),
        would_flip(Board, Row, Col, Player)).

% Check if placing at (Row, Col) would flip any opponent pieces
would_flip(Board, Row, Col, Player) :-
    opponent(Player, Opponent),
    between(1, 8, DR), between(1, 8, DC),
    (DR =:= Row -> (DC =:= Col -> fail ; true) ; true),
    member(DR-DC, [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]),
    Direction = DR-DC,
    find_flips_in_direction(Board, Row, Col, Player, Opponent, Direction, Flips),
    Flips \= [],
    !.

% Find flips in a given direction
find_flips_in_direction(Board, Row, Col, Player, Opponent, DR-DC, Flips) :-
    R1 is Row + DR,
    C1 is Col + DC,
    in_bounds(R1, C1),
    nth1(R1, Board, RowList),
    nth1(C1, RowList, Piece),
    Piece = Opponent,
    !,
    collect_pieces(Board, R1, C1, DR, DC, Player, Opponent, [], Flips).

in_bounds(R, C) :- between(1, 8, R), between(1, 8, C).

collect_pieces(Board, R, C, DR, DC, Player, Opponent, Acc, Flips) :-
    nth1(R, Board, RowList),
    nth1(C, RowList, Piece),
    (Piece = Player ->
        Flips = Acc
    ; Piece = Opponent ->
        R1 is R + DR,
        C1 is C + DC,
        in_bounds(R1, C1),
        collect_pieces(Board, R1, C1, DR, DC, Player, Opponent, [R-C|Acc], Flips)
    ; Flips = []).

% Apply a move
apply_move(State, place(Row, Col), NewState) :-
    State = state(Board, Player),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    would_flip(Board, Row, Col, Player),
    set_cell(Row, Col, Board, Player, Board1),
    flip_all_directions(Board1, Row, Col, Player, Board2),
    opponent(Player, NextPlayer),
    NewState = state(Board2, NextPlayer).

apply_move(State, pass, NewState) :-
    State = state(Board, Player),
    legal_move(State, pass),
    opponent(Player, NextPlayer),
    NewState = state(Board, NextPlayer).

% Flip pieces in all directions
flip_all_directions(Board, Row, Col, Player, FinalBoard) :-
    findall(Flips,
            (member(DR-DC, [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]),
             find_flips_in_direction(Board, Row, Col, Player, _, DR-DC, Flips)),
            AllFlipsLists),
    flatten(AllFlipsLists, AllFlips),
    flip_pieces(Board, AllFlips, Player, FinalBoard).

flip_pieces(Board, [], _, Board).
flip_pieces(Board, [R-C|Rest], Player, FinalBoard) :-
    set_cell(R, C, Board, Player, Board1),
    flip_pieces(Board1, Rest, Player, FinalBoard).

% Opponent relation
opponent(black, white).
opponent(white, black).

% Game over conditions
game_over(State, Winner) :-
    State = state(Board, _),
    \+ legal_move(State, place(_, _)),
    opponent(_, Opponent),
    \+ legal_move(state(Board, Opponent), place(_, _)),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount -> Winner = black
    ; WhiteCount > BlackCount -> Winner = white
    ; Winner = draw).

% Count pieces of a player
count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(=(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

% Render the board
render_state(state(Board, Player)) :-
    format("Current player: ~w~n", [Player]),
    format("  1 2 3 4 5 6 7 8~n"),
    render_rows(Board, 1).

render_rows([], _).
render_rows([Row|Rest], N) :-
    format("~w ", [N]),
    render_row(Row),
    nl,
    N1 is N + 1,
    render_rows(Rest, N1).

render_row([]).
render_row([Cell|Rest]) :-
    (Cell = empty -> format(". ")
    ; Cell = black -> format("B ")
    ; format("W ")),
    render_row(Rest).
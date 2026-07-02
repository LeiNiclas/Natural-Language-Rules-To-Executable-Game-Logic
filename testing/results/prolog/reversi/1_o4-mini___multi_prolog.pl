:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList): NewList is List with element at position Index replaced by Value
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Value, Board, NewBoard): NewBoard is Board with cell at (Row,Col) set to Value
set_cell(Row, Col, V, Board, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, V, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State): State is the starting Reversi position with black to move
initial_state(state([
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,white,black,empty,empty,empty],
    [empty,empty,empty,black,white,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty]
], black)).

% current_player(State, Player): Player is the one to move in State
current_player(state(_, P), P).

% opponent(Player, Opp)
opponent(black, white).
opponent(white, black).

% in_bounds(Row, Col)
in_bounds(Row, Col) :-
    Row >= 1, Row =< 8,
    Col >= 1, Col =< 8.

% cell(Board, Row, Col, Cell)
cell(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

% directions(List of direction vectors)
directions([(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]).

% flip_direction(Board, Player, Row, Col, DR, DC): true if placing at (Row,Col) flips in direction DR,DC
flip_direction(Board, Player, Row, Col, DR, DC) :-
    opponent(Player, Opp),
    R1 is Row + DR,
    C1 is Col + DC,
    in_bounds(R1, C1),
    cell(Board, R1, C1, Opp),
    scan(R1, C1, DR, DC, Board, Player).

% scan(Row, Col, DR, DC, Board, Player): scans along direction until Player piece is found
scan(Row, Col, DR, DC, Board, Player) :-
    R2 is Row + DR,
    C2 is Col + DC,
    in_bounds(R2, C2),
    cell(Board, R2, C2, Cell),
    ( Cell = Player
    ; opponent(Player, Opp),
      Cell = Opp,
      scan(R2, C2, DR, DC, Board, Player)
    ).

% legal_place(Board, Player, Row, Col): true for each legal placement move
legal_place(Board, Player, Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col),
    cell(Board, Row, Col, empty),
    once((directions(Dirs), member((DR, DC), Dirs), flip_direction(Board, Player, Row, Col, DR, DC))).

% legal_move(State, Move): generates all legal moves for the current player
legal_move(state(Board, Player), place(Player, Row, Col)) :-
    legal_place(Board, Player, Row, Col).
legal_move(state(Board, Player), pass(Player)) :-
    \+ legal_place(Board, Player, _, _).

% apply_move(State, Move, NewState): applies a legal move to produce NewState
apply_move(state(Board, Player), place(Player, Row, Col), state(NewBoard, Next)) :-
    legal_place(Board, Player, Row, Col),
    set_cell(Row, Col, Player, Board, Board1),
    directions(Dirs),
    findall((DR, DC),
        (member((DR, DC), Dirs), flip_direction(Board, Player, Row, Col, DR, DC)),
        Flips),
    foldl(flip_cells(Row, Col, Player), Flips, Board1, Board2),
    opponent(Player, Next),
    NewBoard = Board2.

apply_move(state(Board, Player), pass(Player), state(Board, Next)) :-
    \+ legal_place(Board, Player, _, _),
    opponent(Player, Next).

% flip_cells(Row, Col, Player, (DR,DC), BoardIn, BoardOut): flips pieces along one direction
flip_cells(Row, Col, Player, (DR, DC), BoardIn, BoardOut) :-
    R1 is Row + DR,
    C1 is Col + DC,
    flip_line(R1, C1, DR, DC, Player, BoardIn, BoardOut).

% flip_line(Row, Col, DR, DC, Player, BoardIn, BoardOut): flips until Player piece reached
flip_line(Row, Col, _, _, Player, Board, Board) :-
    cell(Board, Row, Col, Player), !.
flip_line(Row, Col, DR, DC, Player, BoardIn, BoardOut) :-
    set_cell(Row, Col, Player, BoardIn, BoardMid),
    R2 is Row + DR,
    C2 is Col + DC,
    flip_line(R2, C2, DR, DC, Player, BoardMid, BoardOut).

% count_pieces(Board, Player, Count): number of cells with Player
count_pieces(Board, Player, Count) :-
    findall((R,C), cell(Board, R, C, Player), L),
    length(L, Count).

% boards_full(Board): true if no empty cells
boards_full(Board) :-
    \+ ( cell(Board, R, C, empty) ).

% game_over(State, Winner): Winner is player with more pieces or draw; fails if ongoing
game_over(state(Board, _), Winner) :-
    ( boards_full(Board)
    ; \+ legal_place(Board, black, _, _),
      \+ legal_place(Board, white, _, _)
    ),
    count_pieces(Board, black, BCount),
    count_pieces(Board, white, WCount),
    ( BCount > WCount
    -> Winner = black
    ; WCount > BCount
    -> Winner = white
    ; Winner = draw
    ).

% render_state(State): print the board with row and column labels and current player
render_state(state(Board, Player)) :-
    print_rows(Board, 1),
    print_cols,
    current_player_char(Player, PChar),
    format('Current player: ~w~n', [PChar]).

print_rows([], _).
print_rows([Row|Rest], N) :-
    format('~w | ', [N]),
    print_row(Row),
    nl,
    N1 is N+1,
    print_rows(Rest, N1).

print_row([]).
print_row([Cell|Rest]) :-
    cell_char(Cell, CChar),
    format('~w', [CChar]),
    ( Rest \= [] -> format(' ') ; true),
    print_row(Rest).

print_cols :-
    format('    '),
    print_col_nums(1).

print_col_nums(9) :-
    nl.
print_col_nums(N) :-
    N < 9,
    format('~w', [N]),
    ( N < 8 -> format(' ') ; true),
    N1 is N+1,
    print_col_nums(N1).

cell_char(empty, '.').
cell_char(black, b).
cell_char(white, w).

current_player_char(black, b).
current_player_char(white, w).
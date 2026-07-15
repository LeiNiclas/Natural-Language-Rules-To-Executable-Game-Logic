:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, V, Board, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, V, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(Board, black)) :-
    Board = [
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,white,black,empty,empty,empty],
        [empty,empty,empty,black,white,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty],
        [empty,empty,empty,empty,empty,empty,empty,empty]
    ].

current_player(state(_, P), P).

opponent(black, white).
opponent(white, black).

in_bounds(Row, Col) :-
    Row >= 1, Row =< 8,
    Col >= 1, Col =< 8.

direction(-1, -1).
direction(-1, 0).
direction(-1, 1).
direction(0, -1).
direction(0, 1).
direction(1, -1).
direction(1, 0).
direction(1, 1).

find_flippable(Board, Player, Row, Col, DR, DC, Flips) :-
    opponent(Player, Opp),
    NextRow is Row + DR,
    NextCol is Col + DC,
    in_bounds(NextRow, NextCol),
    nth1(NextRow, Board, NextRowList),
    nth1(NextCol, NextRowList, Opp),
    collect_flips(Board, Player, Opp, NextRow, NextCol, DR, DC, [(NextRow,NextCol)], Flips).

collect_flips(Board, Player, Opp, CurrRow, CurrCol, DR, DC, Acc, Flips) :-
    NextRow is CurrRow + DR,
    NextCol is CurrCol + DC,
    in_bounds(NextRow, NextCol),
    nth1(NextRow, Board, RowList),
    nth1(NextCol, RowList, Cell),
    (   Cell == Opp
    ->  collect_flips(Board, Player, Opp, NextRow, NextCol, DR, DC, [(NextRow,NextCol)|Acc], Flips)
    ;   Cell == Player
    ->  Flips = Acc
    ;   fail
    ).

has_flippable(Board, Player, Row, Col) :-
    direction(DR, DC),
    find_flippable(Board, Player, Row, Col, DR, DC, Flips),
    Flips \= [],
    !.

legal_move(state(Board, Player), move(place, Row, Col)) :-
    between(1, 8, Row),
    between(1, 8, Col),
    nth1(Row, Board, BoardRow),
    nth1(Col, BoardRow, empty),
    has_flippable(Board, Player, Row, Col).

legal_move(state(Board, Player), move(pass)) :-
    \+ legal_move(state(Board, Player), move(place, _, _)).

flip_piece(Player, (R, C), Board, NewBoard) :-
    set_cell(R, C, Player, Board, NewBoard).

apply_move(state(Board, Player), move(place, Row, Col), state(FinalBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(place, Row, Col)),
    findall(Flips, (direction(DR, DC), find_flippable(Board, Player, Row, Col, DR, DC, Flips)), ListOfLists),
    append(ListOfLists, AllFlips),
    set_cell(Row, Col, Player, Board, Board1),
    foldl(flip_piece(Player), AllFlips, Board1, Board2),
    opponent(Player, NextPlayer),
    FinalBoard = Board2.

apply_move(state(Board, Player), move(pass), state(Board, NextPlayer)) :-
    legal_move(state(Board, Player), move(pass)),
    opponent(Player, NextPlayer).

game_over(state(Board,_), Winner) :-
    append(Board, Cells),
    (
      \+ member(empty, Cells)
    ; \+ legal_move(state(Board, black), move(place, _, _)),
      \+ legal_move(state(Board, white), move(place, _, _))
    ),
    include(==(black), Cells, Blacks),
    length(Blacks, BCount),
    include(==(white), Cells, Whites),
    length(Whites, WCount),
    (   BCount > WCount
    ->  Winner = black
    ;   WCount > BCount
    ->  Winner = white
    ;   Winner = draw
    ).

% render_state(+State) prints an 8x8 board with rows 1-8 and columns 1-8
render_state(state(Board, Player)) :-
    print_rows(Board, 1),
    print_col_labels,
    player_abbrev(Player, Abbrev),
    format('Current player: ~w~n', [Abbrev]).

% print_rows(+Rows, +Index) prints each row with its number
print_rows([], _).
print_rows([Row|Rest], Index) :-
    format('~w | ', [Index]),
    print_cells(Row),
    nl,
    Next is Index + 1,
    print_rows(Rest, Next).

% print_cells(+Cells) prints each cell with a space
print_cells([]).
print_cells([C|Cs]) :-
    print_cell(C),
    write(' '),
    print_cells(Cs).

% print_cell(+Cell) prints '.' for empty, 'b' for black, 'w' for white
print_cell(empty) :- write('.').
print_cell(black) :- write('b').
print_cell(white) :- write('w').

% print_col_labels prints column numbers below the board
print_col_labels :-
    write('    '),
    print_col_numbers(1).

print_col_numbers(9) :- nl.
print_col_numbers(N) :-
    N =< 8,
    format('~w ', [N]),
    N1 is N + 1,
    print_col_numbers(N1).

% player_abbrev(+Player, -Abbrev) gives 'b' or 'w'
player_abbrev(black, b).
player_abbrev(white, w).


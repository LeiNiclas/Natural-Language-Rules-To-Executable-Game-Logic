:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(Board, black)) :-
    Board = [[empty,empty,empty,empty,empty,empty,empty,empty],
             [empty,empty,empty,empty,empty,empty,empty,empty],
             [empty,empty,empty,empty,empty,empty,empty,empty],
             [empty,empty,empty,white,black,empty,empty,empty],
             [empty,empty,empty,black,white,empty,empty,empty],
             [empty,empty,empty,empty,empty,empty,empty,empty],
             [empty,empty,empty,empty,empty,empty,empty,empty],
             [empty,empty,empty,empty,empty,empty,empty,empty]].

current_player(state(_, Player), Player).

valid_position(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

opponent_color(black, white).
opponent_color(white, black).

direction_offset(north, -1, 0).
direction_offset(south, 1, 0).
direction_offset(east, 0, 1).
direction_offset(west, 0, -1).
direction_offset(northeast, -1, 1).
direction_offset(northwest, -1, -1).
direction_offset(southeast, 1, 1).
direction_offset(southwest, 1, -1).

check_direction_flips(Board, Row, Col, RowDir, ColDir, Player, Flips) :-
    opponent_color(Player, Opponent),
    Row1 is Row + RowDir,
    Col1 is Col + ColDir,
    valid_position(Row1, Col1),
    nth1(Row1, Board, RowList),
    nth1(Col1, RowList, Cell),
    Cell == Opponent,
    check_direction_flips_cont(Board, Row1, Col1, RowDir, ColDir, Player, [Row1-Col1], Flips).

check_direction_flips_cont(Board, Row, Col, RowDir, ColDir, Player, Acc, Flips) :-
    Row1 is Row + RowDir,
    Col1 is Col + ColDir,
    valid_position(Row1, Col1),
    nth1(Row1, Board, RowList),
    nth1(Col1, RowList, Cell),
    (Cell == Player ->
        Flips = Acc
    ; Cell == empty ->
        fail
    ;   check_direction_flips_cont(Board, Row1, Col1, RowDir, ColDir, Player, [Row1-Col1|Acc], Flips)
    ).

find_flippable_pieces(Board, Row, Col, Player, AllFlips) :-
    findall(Flips,
            (direction_offset(_, RowDir, ColDir),
             check_direction_flips(Board, Row, Col, RowDir, ColDir, Player, Flips)),
            FlipsList),
    flatten(FlipsList, AllFlips).

is_legal_placement(Board, Row, Col, Player) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell),
    Cell == empty,
    find_flippable_pieces(Board, Row, Col, Player, Flips),
    Flips \= [].

has_legal_move(Board, Player) :-
    valid_position(Row, Col),
    is_legal_placement(Board, Row, Col, Player),
    !.

legal_move(state(Board, Player), move(place, Row, Col)) :-
    is_legal_placement(Board, Row, Col, Player).

legal_move(state(Board, Player), move(pass)) :-
    \+ has_legal_move(Board, Player).

apply_move(state(Board, Player), move(place, Row, Col), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(place, Row, Col)),
    set_cell(Board, Row, Col, Player, BoardWithNewPiece),
    find_flippable_pieces(Board, Row, Col, Player, Flips),
    update_board_with_flips(BoardWithNewPiece, Flips, Player, NewBoard),
    opponent_color(Player, NextPlayer).

apply_move(state(Board, Player), move(pass), state(Board, NextPlayer)) :-
    legal_move(state(Board, Player), move(pass)),
    opponent_color(Player, NextPlayer).

update_board_with_flips(Board, [], _, Board).

update_board_with_flips(Board, [Row-Col|Flips], Player, NewBoard) :-
    set_cell(Board, Row, Col, Player, UpdatedBoard),
    update_board_with_flips(UpdatedBoard, Flips, Player, NewBoard).

count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(==(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

no_legal_moves(Board, Player) :-
    \+ has_legal_move(Board, Player).

game_over(State, Winner) :-
    State = state(Board, _),
    no_legal_moves(Board, black),
    no_legal_moves(Board, white),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; WhiteCount > BlackCount ->
        Winner = white
    ; Winner = draw).

game_over(State, Winner) :-
    State = state(Board, _),
    flatten(Board, Cells),
    \+ member(empty, Cells),
    count_pieces(Board, black, BlackCount),
    count_pieces(Board, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; WhiteCount > BlackCount ->
        Winner = white
    ; Winner = draw).

render_state(state(Board, CurrentPlayer)) :-
    write('  a b c d e f g h'), nl,
    render_board_rows(Board, 1),
    write('  a b c d e f g h'), nl,
    format('Current player: ~w', [CurrentPlayer]), nl.

render_board_rows([], _).
render_board_rows([Row|Rows], RowNum) :-
    format('~w |', [RowNum]),
    render_board_row(Row),
    nl,
    RowNum1 is RowNum + 1,
    render_board_rows(Rows, RowNum1).

render_board_row([]).
render_board_row([Cell|Cells]) :-
    (Cell = empty -> write(' .')
    ; Cell = black -> write(' b')
    ; Cell = white -> write(' w')
    ),
    render_board_row(Cells).
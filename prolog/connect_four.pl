:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list of 6 rows, 7 columns
% Each cell is empty, red, or yellow
% Row 1 = top row, Col 1 = leftmost column

% state(Board)
% Board = list of 6 rows, each row is a list of 7 cells

initial_state(state([
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty]
])).

current_player(state(Board), Player) :-
    findall(Red, (member(Row, Board), member(Red, Row), Red = red), Reds),
    findall(Yellow, (member(Row, Board), member(Yellow, Row), Yellow = yellow), Yellows),
    length(Reds, RedCount),
    length(Yellows, YellowCount),
    (RedCount =:= YellowCount -> Player = red ; Player = yellow).

legal_move(state(Board), column(Col)) :-
    between(1, 7, Col),
    nth1(6, Board, BottomRow),
    nth1(Col, BottomRow, Cell),
    Cell = empty.

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

apply_move(state(Board), column(Col), state(NewBoard)) :-
    current_player(state(Board), Player),
    find_drop_row(1, Col, Board, Row),
    set_cell(Row, Col, Board, Player, NewBoard).

find_drop_row(6, Col, Board, 6) :-
    nth1(6, Board, Row),
    nth1(Col, Row, empty), !.
find_drop_row(Row, Col, Board, DropRow) :-
    NextRow is Row + 1,
    nth1(NextRow, Board, NextRowData),
    nth1(Col, NextRowData, empty),
    !,
    find_drop_row(NextRow, Col, Board, DropRow).
find_drop_row(Row, Col, Board, Row) :-
    nth1(Row, Board, RowData),
    nth1(Col, RowData, empty),
    BelowRow is Row + 1,
    nth1(BelowRow, Board, BelowRowData),
    nth1(Col, BelowRowData, Occupied),
    Occupied \= empty.

game_over(state(Board), Winner) :-
    (check_winner(Board, red) -> Winner = red ;
     check_winner(Board, yellow) -> Winner = yellow ;
     (forall(member(Row, Board), \+ member(empty, Row)) -> Winner = draw ;
      fail)).

check_winner(Board, Player) :-
    check_horizontal(Board, Player) ;
    check_vertical(Board, Player) ;
    check_diagonal_up(Board, Player) ;
    check_diagonal_down(Board, Player).

check_horizontal(Board, Player) :-
    member(Row, Board),
    append(_, [Player, Player, Player, Player|_], Row).

check_vertical(Board, Player) :-
    between(1, 3, StartRow),
    between(1, 7, Col),
    EndRow is StartRow + 3,
    findall(Cell, (between(StartRow, EndRow, Row), nth1(Row, Board, RowList), nth1(Col, RowList, Cell)), Cells),
    forall(member(Cell, Cells), Cell = Player).

check_diagonal_up(Board, Player) :-
    between(1, 3, StartRow),
    between(1, 4, StartCol),
    findall(Cell, (
        between(0, 3, Offset),
        Row is StartRow + Offset,
        Col is StartCol + Offset,
        nth1(Row, Board, RowList),
        nth1(Col, RowList, Cell)
    ), Cells),
    forall(member(Cell, Cells), Cell = Player).

check_diagonal_down(Board, Player) :-
    between(4, 6, StartRow),
    between(1, 4, StartCol),
    findall(Cell, (
        between(0, 3, Offset),
        Row is StartRow - Offset,
        Col is StartCol + Offset,
        nth1(Row, Board, RowList),
        nth1(Col, RowList, Cell)
    ), Cells),
    forall(member(Cell, Cells), Cell = Player).

render_state(state(Board)) :-
    format(' 1 2 3 4 5 6 7~n'),
    forall(member(Row, Board),
           (forall(member(Cell, Row),
                   (Cell = empty -> format('. ') ;
                    format('~w ', [Cell]))),
            nl)),
    format('---------------~n').
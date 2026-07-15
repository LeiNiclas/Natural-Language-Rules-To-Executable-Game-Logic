:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Val, Board, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Val, NewRow),
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

valid_coord(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

directions([
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1),           (0, 1),
    (1, -1),  (1, 0),  (1, 1)
]).

collect_flip(Board, Row, Col, DRow, DCol, Player, Acc, Flippable) :-
    NextRow is Row + DRow,
    NextCol is Col + DCol,
    valid_coord(NextRow, NextCol),
    nth1(NextRow, Board, NextRowList),
    nth1(NextCol, NextRowList, Cell),
    (   Cell = Player
    ->  Flippable = Acc
    ;   Cell \= empty,
        collect_flip(Board, NextRow, NextCol, DRow, DCol, Player, [(NextRow, NextCol)|Acc], Flippable)
    ).

pieces_to_flip(Board, Row, Col, DRow, DCol, Player, Flippable) :-
    opponent(Player, Opp),
    FirstRow is Row + DRow,
    FirstCol is Col + DCol,
    valid_coord(FirstRow, FirstCol),
    nth1(FirstRow, Board, FirstRowList),
    nth1(FirstCol, FirstRowList, Opp),
    collect_flip(Board, FirstRow, FirstCol, DRow, DCol, Player, [(FirstRow, FirstCol)], Flippable).

legal_directions(Board, Row, Col, Player, Dirs) :-
    directions(AllDirs),
    findall(
        (DR, DC),
        ( member((DR, DC), AllDirs),
          pieces_to_flip(Board, Row, Col, DR, DC, Player, Flippable),
          Flippable \= []
        ),
        Dirs
    ).

has_legal_place(Board, Player) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    legal_directions(Board, Row, Col, Player, Dirs),
    Dirs \= [].

legal_move(state(Board, Player), move(place, Row, Col)) :-
    has_legal_place(Board, Player),
    valid_coord(Row, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    legal_directions(Board, Row, Col, Player, Dirs),
    Dirs \= [].

legal_move(state(Board, Player), move(pass)) :-
    \+ has_legal_place(Board, Player).

apply_move(state(Board, Player), move(place, Row, Col), state(NewBoard, Opp)) :-
    legal_move(state(Board, Player), move(place, Row, Col)),
    apply_all_flips(Board, Row, Col, Player, NewBoard),
    opponent(Player, Opp).

apply_move(state(Board, Player), move(pass), state(Board, Opp)) :-
    legal_move(state(Board, Player), move(pass)),
    opponent(Player, Opp).

apply_all_flips(Board, Row, Col, Player, NewBoard) :-
    legal_directions(Board, Row, Col, Player, Dirs),
    set_cell(Row, Col, Player, Board, Board1),
    findall(Flips, (member((DR, DC), Dirs), pieces_to_flip(Board, Row, Col, DR, DC, Player, Flips)), ListOfLists),
    append(ListOfLists, AllFlips),
    flip_positions(AllFlips, Player, Board1, NewBoard).

flip_positions([], _, Board, Board).
flip_positions([(R, C)|Rest], Player, Board, NewBoard) :-
    set_cell(R, C, Player, Board, Board1),
    flip_positions(Rest, Player, Board1, NewBoard).

game_over(state(Board, _), Winner) :-
    (   \+ ( nth1(_, Board, Row), nth1(_, Row, empty) )
    ;   \+ has_legal_place(Board, black),
        \+ has_legal_place(Board, white)
    ),
    flatten(Board, Flat),
    findall(_, member(black, Flat), Blacks),
    length(Blacks, BCount),
    findall(_, member(white, Flat), Whites),
    length(Whites, WCount),
    (   BCount > WCount
    ->  Winner = black
    ;   WCount > BCount
    ->  Winner = white
    ;   Winner = draw
    ).

% render_state prints the board and current player
render_state(state(Board, Player)) :-
    print_rows(Board, 1),
    format('    1 2 3 4 5 6 7 8~n', []),
    map_player(Player, Sym),
    format('Current player: ~w~n', [Sym]).

% print_rows(BoardRows, RowNum) prints each row with its number
print_rows([], _).
print_rows([Row|Rest], RowNum) :-
    format('~w | ', [RowNum]),
    print_row_elements(Row),
    nl,
    Next is RowNum + 1,
    print_rows(Rest, Next).

% print_row_elements prints cell symbols separated by spaces
print_row_elements([Cell]) :-
    cell_symbol(Cell, Sym),
    write(Sym).
print_row_elements([Cell|Rest]) :-
    cell_symbol(Cell, Sym),
    write(Sym), write(' '),
    print_row_elements(Rest).

% cell_symbol maps board atoms to characters
cell_symbol(empty, '.').
cell_symbol(black, 'b').
cell_symbol(white, 'w').

% map_player maps player atom to short symbol
map_player(black, 'b').
map_player(white, 'w').

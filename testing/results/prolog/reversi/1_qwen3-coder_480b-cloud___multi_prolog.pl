:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

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

current_player(state(_, Player), Player).

legal_move(State, Move) :-
    State = state(Board, Player),
    findall(place(Player, R, C), (
        between(1, 8, R),
        between(1, 8, C),
        nth1(R, Board, Row),
        nth1(C, Row, empty),
        is_valid_placement(Board, R, C, Player)
    ), Moves),
    (   Moves = [] ->
        Move = pass(Player)
    ;   member(Move, Moves)
    ).

is_valid_placement(Board, R, C, Player) :-
    opponent(Player, Opponent),
    direction(DR, DC),
    R1 is R + DR,
    C1 is C + DC,
    R1 >= 1, R1 =< 8,
    C1 >= 1, C1 =< 8,
    nth1(R1, Board, Row1),
    nth1(C1, Row1, Opponent),
    check_direction(Board, R1, C1, DR, DC, Player).

check_direction(Board, R, C, DR, DC, Player) :-
    R1 is R + DR,
    C1 is C + DC,
    (   R1 < 1 ; R1 > 8 ; C1 < 1 ; C1 > 8 ->
        fail
    ;   nth1(R1, Board, Row1),
        nth1(C1, Row1, Cell),
        (   Cell = Player ->
            true
        ;   opponent(Player, Opponent),
            Cell = Opponent ->
            check_direction(Board, R1, C1, DR, DC, Player)
        ;   fail
        )
    ).

opponent(black, white).
opponent(white, black).

direction(-1, -1).
direction(-1, 0).
direction(-1, 1).
direction(0, -1).
direction(0, 1).
direction(1, -1).
direction(1, 0).
direction(1, 1).

apply_move(State, pass(Player), NewState) :-
    State = state(Board, Player),
    current_player(State, Player),
    findall(place(Player, R, C), (
        between(1, 8, R),
        between(1, 8, C),
        nth1(R, Board, Row),
        nth1(C, Row, empty),
        is_valid_placement(Board, R, C, Player)
    ), Moves),
    Moves = [],
    opponent(Player, NextPlayer),
    NewState = state(Board, NextPlayer).

apply_move(State, place(Player, Row, Col), NewState) :-
    State = state(Board, Player),
    nth1(Row, Board, BoardRow),
    nth1(Col, BoardRow, empty),
    is_valid_placement(Board, Row, Col, Player),
    set_cell(Row, Col, Board, Player, BoardWithPiece),
    flip_pieces(BoardWithPiece, Row, Col, Player, BoardAfterFlips),
    opponent(Player, NextPlayer),
    NewState = state(BoardAfterFlips, NextPlayer).

flip_pieces(Board, Row, Col, Player, NewBoard) :-
    findall((DR, DC), direction(DR, DC), Directions),
    foldl(flip_in_direction(Player, Row, Col), Directions, Board, NewBoard).

flip_in_direction(Player, Row, Col, (DR, DC), Board, NewBoard) :-
    (   should_flip_in_direction(Board, Row, Col, DR, DC, Player, PositionsToFlip) ->
        flip_positions(Board, PositionsToFlip, Player, NewBoard)
    ;   NewBoard = Board
    ).

should_flip_in_direction(Board, Row, Col, DR, DC, Player, Positions) :-
    R1 is Row + DR,
    C1 is Col + DC,
    R1 >= 1, R1 =< 8,
    C1 >= 1, C1 =< 8,
    nth1(R1, Board, Row1),
    nth1(C1, Row1, Cell),
    opponent(Player, Opponent),
    Cell = Opponent,
    collect_flippable_pieces(Board, R1, C1, DR, DC, Player, [], Positions).

collect_flippable_pieces(Board, R, C, DR, DC, Player, Acc, Positions) :-
    R >= 1, R =< 8,
    C >= 1, C =< 8,
    nth1(R, Board, Row),
    nth1(C, Row, Cell),
    (   Cell = Player ->
        Positions = Acc
    ;   opponent(Player, Opponent),
        Cell = Opponent ->
        NewR is R + DR,
        NewC is C + DC,
        collect_flippable_pieces(Board, NewR, NewC, DR, DC, Player, [(R,C)|Acc], Positions)
    ;   fail
    ).

flip_positions(Board, [], _, Board).
flip_positions(Board, [(R,C)|Rest], Player, NewBoard) :-
    set_cell(R, C, Board, Player, Board1),
    flip_positions(Board1, Rest, Player, NewBoard).

game_over(State, Winner) :-
    State = state(Board, _),
    findall(Empty, (
        between(1, 8, R),
        between(1, 8, C),
        nth1(R, Board, Row),
        nth1(C, Row, Empty),
        Empty = empty
    ), Empties),
    (   Empties = [] ->
        count_pieces(Board, black, BlackCount),
        count_pieces(Board, white, WhiteCount),
        (   BlackCount > WhiteCount ->
            Winner = black
        ;   WhiteCount > BlackCount ->
            Winner = white
        ;   Winner = draw
        )
    ;   \+ legal_move(State, place(black, _, _)),
        \+ legal_move(State, place(white, _, _)) ->
        count_pieces(Board, black, BlackCount),
        count_pieces(Board, white, WhiteCount),
        (   BlackCount > WhiteCount ->
            Winner = black
        ;   WhiteCount > BlackCount ->
            Winner = white
        ;   Winner = draw
        )
    ).

count_pieces(Board, Player, Count) :-
    flatten(Board, Cells),
    include(=(Player), Cells, PlayerCells),
    length(PlayerCells, Count).

render_state(state(Board, Player)) :-
    write('  a b c d e f g h'), nl,
    render_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

render_rows([], _).
render_rows([Row|Rest], N) :-
    format('~w |', [N]),
    render_row(Row),
    nl,
    N1 is N + 1,
    render_rows(Rest, N1).

render_row([]).
render_row([Cell|Rest]) :-
    (   Cell = empty ->
        write(' .')
    ;   Cell = black ->
        write(' b')
    ;   Cell = white ->
        write(' w')
    ),
    render_row(Rest).
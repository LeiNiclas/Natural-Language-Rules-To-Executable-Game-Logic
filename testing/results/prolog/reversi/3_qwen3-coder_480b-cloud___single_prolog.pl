:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list of 8 rows, each row a list of 8 cells.
% Cell values: empty, black, white
% State: state(Board, CurrentPlayer)

% Helper to update a cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state: 8x8 board with center pieces set
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

% Current player
current_player(state(_, P), P).

% Legal moves
legal_move(State, place(Row, Col)) :-
    state(Board, Player) = State,
    between(1, 8, Row),
    between(1, 8, Col),
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    has_flippable_line(Board, Row, Col, Player).

legal_move(State, pass) :-
    state(Board, Player) = State,
    \+ (between(1, 8, Row),
        between(1, 8, Col),
        nth1(Row, Board, RowList),
        nth1(Col, RowList, empty),
        has_flippable_line(Board, Row, Col, Player)).

% Check if placing at (Row,Col) flips any pieces for Player
has_flippable_line(Board, Row, Col, Player) :-
    opponent(Player, Opponent),
    direction(DR, DC),
    Line = [H|_],
    build_line(Board, Row, Col, DR, DC, Line),
    H = Opponent,
    member(P, Line),
    P = Player,
    !.

% All 8 directions
direction(-1, -1). direction(-1, 0). direction(-1, 1).
direction(0, -1).                direction(0, 1).
direction(1, -1).  direction(1, 0).  direction(1, 1).

% Build a line of pieces in a given direction
build_line(Board, Row, Col, DR, DC, [Cell|Rest]) :-
    R1 is Row + DR,
    C1 is Col + DC,
    R1 >= 1, R1 =< 8,
    C1 >= 1, C1 =< 8,
    nth1(R1, Board, RowList),
    nth1(C1, RowList, Cell),
    (Cell = empty ->
        Rest = []
    ;
        build_line(Board, R1, C1, DR, DC, Rest)
    ).

% Apply move
apply_move(State, place(Row, Col), NewState) :-
    state(Board, Player) = State,
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty),
    has_flippable_line(Board, Row, Col, Player),
    set_cell(Row, Col, Board, Player, BoardWithMove),
    flip_lines(BoardWithMove, Row, Col, Player, BoardFlipped),
    opponent(Player, NextPlayer),
    NewState = state(BoardFlipped, NextPlayer).

apply_move(State, pass, NewState) :-
    legal_move(State, pass),
    state(Board, Player) = State,
    opponent(Player, NextPlayer),
    NewState = state(Board, NextPlayer).

% Flip lines in all directions
flip_lines(Board, Row, Col, Player, FinalBoard) :-
    findall((DR,DC), direction(DR,DC), Directions),
    foldl(flip_in_direction(Player,Row,Col), Directions, Board, FinalBoard).

flip_in_direction(Player, Row, Col, (DR,DC), Board, NewBoard) :-
    (build_flippable_line(Board, Row, Col, DR, DC, Player, Line) ->
        flip_segment(Board, Row, Col, DR, DC, Line, NewBoard)
    ;
        NewBoard = Board
    ).

build_flippable_line(Board, Row, Col, DR, DC, Player, [H|T]) :-
    R1 is Row + DR,
    C1 is Col + DC,
    nth1(R1, Board, RowList),
    nth1(C1, RowList, H),
    (H = Player ->
        T = []
    ;
        H \= empty,
        build_flippable_line(Board, R1, C1, DR, DC, Player, T)
    ).

flip_segment(Board, Row, Col, DR, DC, Line, NewBoard) :-
    flip_segment_(Board, Row, Col, DR, DC, Line, NewBoard).

flip_segment_(Board, _, _, _, _, [], Board).
flip_segment_(Board, Row, Col, DR, DC, [H|T], NewBoard) :-
    (H = empty ; H = black ; H = white),
    R1 is Row + DR,
    C1 is Col + DC,
    nth1(R1, Board, RowList),
    nth1(C1, RowList, H),
    set_cell(R1, C1, Board, H, Board1),
    flip_segment_(Board1, R1, C1, DR, DC, T, NewBoard).

% Opponent player
opponent(black, white).
opponent(white, black).

% Game over conditions
game_over(State, Winner) :-
    legal_move(State, pass),
    apply_move(State, pass, State2),
    legal_move(State2, pass),
    count_pieces(State2, black, BlackCount),
    count_pieces(State2, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; WhiteCount > BlackCount ->
        Winner = white
    ; Winner = draw
    ).

% Count pieces for a player
count_pieces(state(Board, _), Player, Count) :-
    flatten(Board, Flat),
    include(=(Player), Flat, Pieces),
    length(Pieces, Count).

% Render state
render_state(state(Board, Player)) :-
    forall(between(1,8,Row),
           (nth1(Row, Board, RowList),
            forall(between(1,8,Col),
                   (nth1(Col, RowList, Cell),
                    (Cell = empty -> format(' .') ;
                     Cell = black -> format(' B') ;
                     format(' W')))),
            nl)),
    format('Current player: ~w~n', [Player]).
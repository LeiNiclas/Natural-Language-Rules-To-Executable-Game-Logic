:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 2D list (8x8), row-major order.
% state(Board, CurrentPlayer)
% Board = [[Row1], [Row2], ..., [Row8]]
% CurrentPlayer = black | white

% Helper to update a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state: 8x8 board with center pieces set
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

current_player(state(_, P), P).

% Legal move generator
legal_move(State, Move) :-
    State = state(Board, Player),
    (   findall(place(Row,Col), (
                between(1,8,Row),
                between(1,8,Col),
                nth1(Row, Board, RowList),
                nth1(Col, RowList, empty),
                is_valid_placement(Board, Player, Row, Col)
            ), Placements),
        Placements = [] ->
        Move = pass
    ;   member(Move, Placements)
    ).

% Check if placing at (Row,Col) is valid for Player
is_valid_placement(Board, Player, Row, Col) :-
    % Opponent color
    (Player = black -> Opp = white ; Opp = black),
    % Check all 8 directions
    member(DR, [-1,0,1]),
    member(DC, [-1,0,1]),
    (DR = 0, DC = 0 -> fail ; true),
    DirRow is Row + DR,
    DirCol is Col + DC,
    nth1(DirRow, Board, DirRowList) ->
    nth1(DirCol, DirRowList, Piece),
    Piece = Opp,
    check_direction(Board, Player, Opp, DirRow, DirCol, DR, DC).

% Follow a direction to see if it ends in Player's piece
check_direction(Board, Player, _, Row, Col, _, _) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece),
    Piece = Player, !.
check_direction(Board, Player, Opp, Row, Col, DR, DC) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece),
    Piece = Opp,
    NewRow is Row + DR,
    NewCol is Col + DC,
    check_direction(Board, Player, Opp, NewRow, NewCol, DR, DC).

% Apply a move
apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    (Move = pass ->
        (Player = black -> NextPlayer = white ; NextPlayer = black),
        NewState = state(Board, NextPlayer)
    ; Move = place(Row, Col) ->
        is_valid_placement(Board, Player, Row, Col),
        set_cell(Row, Col, Board, Player, Board1),
        flip_pieces(Board1, Player, Row, Col, Board2),
        (Player = black -> NextPlayer = white ; NextPlayer = black),
        NewState = state(Board2, NextPlayer)
    ).

% Flip pieces in all directions where a line is enclosed
flip_pieces(Board, Player, Row, Col, NewBoard) :-
    (Player = black -> Opp = white ; Opp = black),
    findall(flip(DR,DC), (
        member(DR, [-1,0,1]),
        member(DC, [-1,0,1]),
        (DR = 0, DC = 0 -> fail ; true),
        DirRow is Row + DR,
        DirCol is Col + DC,
        nth1(DirRow, Board, DirRowList) ->
        nth1(DirCol, DirRowList, Piece),
        Piece = Opp,
        check_direction(Board, Player, Opp, DirRow, DirCol, DR, DC)
    ), Directions),
    flip_in_directions(Directions, Board, Player, Row, Col, NewBoard).

% Flip pieces in each valid direction
flip_in_directions([], Board, _, _, _, Board).
flip_in_directions([flip(DR,DC)|Rest], Board, Player, Row, Col, FinalBoard) :-
    flip_line(Board, Player, Row, Col, DR, DC, Board1),
    flip_in_directions(Rest, Board1, Player, Row, Col, FinalBoard).

% Flip a line in one direction
flip_line(Board, Player, Row, Col, DR, DC, NewBoard) :-
    NewRow is Row + DR,
    NewCol is Col + DC,
    nth1(NewRow, Board, RowList),
    nth1(NewCol, RowList, Piece),
    (Piece = Player ->
        NewBoard = Board
    ; Piece \= empty ->
        set_cell(NewRow, NewCol, Board, Player, Board1),
        flip_line(Board1, Player, NewRow, NewCol, DR, DC, NewBoard)
    ).

% Game over conditions
game_over(State, Winner) :-
    State = state(Board, _),
    \+ (between(1,8,R), between(1,8,C),
        nth1(R, Board, RowList),
        nth1(C, RowList, empty)),
    count_pieces(Board, black, BCount),
    count_pieces(Board, white, WCount),
    (BCount > WCount -> Winner = black
    ; WCount > BCount -> Winner = white
    ; Winner = draw).

game_over(State, Winner) :-
    legal_move(State, pass),
    State = state(_, Player),
    (Player = black -> Opp = white ; Opp = black),
    legal_move(state(Board, Opp), pass2),
    Opp = pass2,
    count_pieces(Board, black, BCount),
    count_pieces(Board, white, WCount),
    (BCount > WCount -> Winner = black
    ; WCount > BCount -> Winner = white
    ; Winner = draw).

% Count pieces of a player
count_pieces(Board, Player, Count) :-
    flatten(Board, Flat),
    include(=(Player), Flat, Pieces),
    length(Pieces, Count).

% Render the board
render_state(state(Board, Player)) :-
    format('Current player: ~w~n', [Player]),
    format('  1 2 3 4 5 6 7 8~n'),
    render_rows(Board, 1).

render_rows([], _).
render_rows([Row|Rest], N) :-
    format('~w ', [N]),
    render_row(Row),
    nl,
    N1 is N + 1,
    render_rows(Rest, N1).

render_row([]).
render_row([H|T]) :-
    (H = empty -> format('. ')
    ; H = black -> format('B ')
    ; format('W ')),
    render_row(T).
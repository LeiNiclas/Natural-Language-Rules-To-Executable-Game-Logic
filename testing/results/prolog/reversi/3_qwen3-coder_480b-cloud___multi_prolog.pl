:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state(Board, black)) :-
    Row = [empty,empty,empty,empty,empty,empty,empty,empty],
    Board = [Row,Row,Row,Row,Row,Row,Row,Row],
    set_cell(4, 4, Board, white, Board1),
    set_cell(4, 5, Board1, black, Board2),
    set_cell(5, 4, Board2, black, Board3),
    set_cell(5, 5, Board3, white, Board4).

current_player(state(_, Player), Player).

% Directions: row_delta, col_delta
directions([
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1),           (0, 1),
    (1, -1),  (1, 0),  (1, 1)
]).

% Check if a position is on the board
on_board(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Check if a position is empty
is_empty(state(Board, _), Row, Col) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, empty).

% Get the piece at a position
get_piece(state(Board, _), Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Check if placing a piece at (Row, Col) is legal for Player
is_legal_placement(State, Row, Col, Player) :-
    is_empty(State, Row, Col),
    directions(Directions),
    member((DR, DC), Directions),
    check_direction(State, Row, Col, DR, DC, Player), !.

% Check a direction for a legal placement
check_direction(State, Row, Col, DR, DC, Player) :-
    NR is Row + DR,
    NC is Col + DC,
    on_board(NR, NC),
    get_piece(State, NR, NC, Opponent),
    Opponent \= empty,
    Opponent \= Player,
    check_line(State, NR, NC, DR, DC, Player).

% Check if there's a line of opponent pieces ending in Player's piece
check_line(State, Row, Col, DR, DC, Player) :-
    NR is Row + DR,
    NC is Col + DC,
    on_board(NR, NC),
    get_piece(State, NR, NC, Piece),
    (Piece = Player ->
        true
    ; Piece = empty ->
        fail
    ; Piece \= Player ->
        check_line(State, NR, NC, DR, DC, Player)
    ).

% Generate all legal place moves for a player
legal_place_moves(State, Player, Moves) :-
    findall(place(Player, Row, Col),
            (between(1, 8, Row),
             between(1, 8, Col),
             is_legal_placement(State, Row, Col, Player)),
            Moves).

% Check if there are any legal moves for a player
has_legal_moves(State, Player) :-
    between(1, 8, Row),
    between(1, 8, Col),
    is_legal_placement(State, Row, Col, Player), !.

% Legal move generator
legal_move(State, Move) :-
    State = state(_, Player),
    legal_place_moves(State, Player, Moves),
    (Moves = [] ->
        Move = pass(Player)
    ; member(Move, Moves)
    ).

% Apply a move to the state
apply_move(State, Move, NewState) :-
    State = state(Board, Player),
    next_player(Player, NextPlayer),
    (Move = place(Player, Row, Col) ->
        is_legal_placement(State, Row, Col, Player),
        set_cell(Row, Col, Board, Player, BoardWithPiece),
        flip_pieces(State, Row, Col, Player, BoardWithPiece, BoardAfterFlips),
        NewState = state(BoardAfterFlips, NextPlayer)
    ; Move = pass(Player) ->
        legal_place_moves(State, Player, []),
        NewState = state(Board, NextPlayer)
    ).

% Get the next player
next_player(black, white).
next_player(white, black).

% Flip pieces in all directions after a placement
flip_pieces(State, Row, Col, Player, Board, NewBoard) :-
    directions(Directions),
    foldl(flip_in_direction(State, Row, Col, Player), Directions, Board, NewBoard).

% Flip pieces in one direction
flip_in_direction(State, Row, Col, Player, (DR, DC), AccBoard, NewBoard) :-
    (check_direction(State, Row, Col, DR, DC, Player) ->
        NR is Row + DR,
        NC is Col + DC,
        flip_line(State, NR, NC, DR, DC, Player, AccBoard, NewBoard)
    ; NewBoard = AccBoard
    ).

% Flip a line of pieces
flip_line(State, Row, Col, DR, DC, Player, AccBoard, NewBoard) :-
    get_piece(State, Row, Col, Piece),
    (Piece = Player ->
        NewBoard = AccBoard
    ; Piece \= empty ->
        set_cell(Row, Col, AccBoard, Player, UpdatedBoard),
        NR is Row + DR,
        NC is Col + DC,
        flip_line(State, NR, NC, DR, DC, Player, UpdatedBoard, NewBoard)
    ).

% Check if the game is over and determine the winner
game_over(State, Winner) :-
    \+ has_legal_moves(State, black),
    \+ has_legal_moves(State, white),
    count_pieces(State, black, BlackCount),
    count_pieces(State, white, WhiteCount),
    (BlackCount > WhiteCount ->
        Winner = black
    ; WhiteCount > BlackCount ->
        Winner = white
    ; BlackCount = WhiteCount ->
        Winner = draw
    ).

% Count the number of pieces for a player
count_pieces(state(Board, _), Player, Count) :-
    flatten(Board, Pieces),
    include(=(Player), Pieces, PlayerPieces),
    length(PlayerPieces, Count).

% Render the state
render_state(state(Board, Player)) :-
    write('  1 2 3 4 5 6 7 8'), nl,
    render_board_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

render_board_rows([], _).
render_board_rows([Row|Rows], RowNum) :-
    format('~w ', [RowNum]),
    render_row(Row),
    nl,
    RowNum1 is RowNum + 1,
    render_board_rows(Rows, RowNum1).

render_row([]).
render_row([Cell|Rest]) :-
    (Cell = empty -> write('.')
    ; Cell = black -> write('B')
    ; Cell = white -> write('W')
    ),
    write(' '),
    render_row(Rest).
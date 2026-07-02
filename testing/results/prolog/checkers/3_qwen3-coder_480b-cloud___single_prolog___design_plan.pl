:- use_module(library(lists)).
:- use_module(library(apply)).

% Board representation: 8x8 list of lists
% Pieces: empty, light_man, dark_man, light_king, dark_king
% Rows: 1-8 (top to bottom), Cols: 1-8 (left to right)

% Helper to set cell in 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Initial state
initial_state(state(Board, dark)) :-
    Board = [
        [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
        [dark_man, empty, dark_man, empty, dark_man, empty, dark_man, empty],
        [empty, dark_man, empty, dark_man, empty, dark_man, empty, dark_man],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [empty, empty, empty, empty, empty, empty, empty, empty],
        [light_man, empty, light_man, empty, light_man, empty, light_man, empty],
        [empty, light_man, empty, light_man, empty, light_man, empty, light_man],
        [light_man, empty, light_man, empty, light_man, empty, light_man, empty]
    ].

% Current player
current_player(state(_, Player), Player).

% Get piece at position
get_piece(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% Valid position check
valid_position(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% Check if piece belongs to player
is_player_piece(light_man, light).
is_player_piece(light_king, light).
is_player_piece(dark_man, dark).
is_player_piece(dark_king, dark).

% Check if piece is a king
is_king(light_king).
is_king(dark_king).

% Calculate jump over position
calculate_jump_over(FromRow, FromCol, ToRow, ToCol, JumpRow, JumpCol) :-
    JumpRow is (FromRow + ToRow) // 2,
    JumpCol is (FromCol + ToCol) // 2.

% Find all jump moves for a player
find_all_jumps(Board, Player, Jumps) :-
    findall(move(FR, FC, TR, TC),
            (between(1, 8, FR),
             between(1, 8, FC),
             get_piece(Board, FR, FC, Piece),
             is_player_piece(Piece, Player),
             between(1, 8, TR),
             between(1, 8, TC),
             get_piece(Board, TR, TC, empty),
             AbsRow is abs(TR - FR),
             AbsCol is abs(TC - FC),
             AbsRow =:= 2,
             AbsCol =:= 2,
             calculate_jump_over(FR, FC, TR, TC, JR, JC),
             get_piece(Board, JR, JC, JumpedPiece),
             is_player_piece(JumpedPiece, Opponent),
             Player \= Opponent,
             valid_position(JR, JC)),
            Jumps).

% Find all simple moves for a player
find_all_simple_moves(Board, Player, Moves) :-
    findall(move(FR, FC, TR, TC),
            (between(1, 8, FR),
             between(1, 8, FC),
             get_piece(Board, FR, FC, Piece),
             is_player_piece(Piece, Player),
             between(1, 8, TR),
             between(1, 8, TC),
             get_piece(Board, TR, TC, empty),
             AbsRow is abs(TR - FR),
             AbsCol is abs(TC - FC),
             AbsRow =:= 1,
             AbsCol =:= 1,
             (is_king(Piece) ->
                 true
             ;
                 (Player = dark ->
                     TR > FR
                 ;
                     TR < FR
                 )
             )),
            Moves).

% Check if player has any legal moves
has_legal_move(Board, Player) :-
    find_all_jumps(Board, Player, Jumps),
    (Jumps \= [] -> true ; find_all_simple_moves(Board, Player, Moves), Moves \= []).

% Count pieces for a player
count_pieces(Board, Player, Count) :-
    flatten(Board, Pieces),
    include(is_player_piece(_, Player), Pieces, PlayerPieces),
    length(PlayerPieces, Count).

% Promote piece when reaching promotion row
promote_piece(dark_man, 8, dark_king).
promote_piece(light_man, 1, light_king).
promote_piece(Piece, _, Piece) :-
    Piece \= dark_man,
    Piece \= light_man.

% Legal move
legal_move(State, Move) :-
    State = state(Board, Player),
    find_all_jumps(Board, Player, Jumps),
    (Jumps = [] ->
        find_all_simple_moves(Board, Player, Moves),
        member(Move, Moves)
    ;
        member(Move, Jumps)
    ).

% Apply move with multiple jump handling
apply_move(state(Board, Player), move(FR, FC, TR, TC), NewState) :-
    get_piece(Board, FR, FC, Piece),
    is_player_piece(Piece, Player),
    get_piece(Board, TR, TC, empty),
    AbsRow is abs(TR - FR),
    AbsCol is abs(TC - FC),
    (AbsRow =:= 1, AbsCol =:= 1 ->
        % Simple move
        (is_king(Piece) ->
            true
        ;
            (Player = dark ->
                TR > FR
            ;
                TR < FR
            )
        ),
        promote_piece(Piece, TR, NewPiece),
        set_cell(FR, FC, Board, empty, Board1),
        set_cell(TR, TC, Board1, NewPiece, NewBoard),
        (Player = dark -> NextPlayer = light ; NextPlayer = dark),
        NewState = state(NewBoard, NextPlayer)
    ;
        AbsRow =:= 2, AbsCol =:= 2 ->
        % Jump move
        calculate_jump_over(FR, FC, TR, TC, JR, JC),
        get_piece(Board, JR, JC, JumpedPiece),
        is_player_piece(JumpedPiece, Opponent),
        Player \= Opponent,
        set_cell(FR, FC, Board, empty, Board1),
        set_cell(JR, JC, Board1, empty, Board2),
        promote_piece(Piece, TR, NewPiece),
        set_cell(TR, TC, Board2, NewPiece, NewBoard),
        % Check for additional jumps
        find_all_jumps(NewBoard, Player, RemainingJumps),
        (memberchk(move(TR, TC, _, _), RemainingJumps) ->
            NewState = state(NewBoard, Player)
        ;
            (Player = dark -> NextPlayer = light ; NextPlayer = dark),
            NewState = state(NewBoard, NextPlayer)
        )
    ).

% Game over conditions
game_over(state(Board, _), Winner) :-
    count_pieces(Board, light, LightCount),
    count_pieces(Board, dark, DarkCount),
    (LightCount = 0 ->
        Winner = dark
    ;
        DarkCount = 0 ->
        Winner = light
    ;
        \+ has_legal_move(Board, light) ->
        Winner = dark
    ;
        \+ has_legal_move(Board, dark) ->
        Winner = light
    ).

% Render state
render_state(state(Board, Player)) :-
    writeln('  1 2 3 4 5 6 7 8'),
    foldl(render_row, Board, 1, _),
    format('Current player: ~w~n', [Player]).

render_row(Row, Index, NextIndex) :-
    format('~w ', [Index]),
    maplist(render_cell, Row),
    nl,
    NextIndex is Index + 1.

render_cell(empty) :- write('. ').
render_cell(light_man) :- write('o ').
render_cell(dark_man) :- write('x ').
render_cell(light_king) :- write('O ').
render_cell(dark_king) :- write('X ').
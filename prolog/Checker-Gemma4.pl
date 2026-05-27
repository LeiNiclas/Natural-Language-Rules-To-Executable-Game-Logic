:- use_module(library(lists)).
:- use_module(library(apply)).

% ==== BOILERPLATE ====
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% ==== INITIAL STATE ====
% State: state(Board, CurrentPlayer, MustJumpPieceIndex)
initial_state(state(Board, 'black', 'none')) :-
    EmptyBoard = [ '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__',
                   '__','__','__','__','__','__','__','__' ],
    % Red pieces (Ranks 1, 2, 3)
    set_nth1(1, EmptyBoard, 'R', B1),
    set_nth1(3, B1, 'R', B2),
    set_nth1(5, B2, 'R', B3),
    set_nth1(7, B3, 'R', B4),
    set_nth1(10, B4, 'R', B5),
    set_nth1(12, B5, 'R', B6),
    set_nth1(14, B6, 'R', B7),
    set_nth1(16, B7, 'R', B8),
    set_nth1(17, B8, 'R', B9),
    set_nth1(19, B9, 'R', B10),
    set_nth1(21, B10, 'R', B11),
    set_nth1(23, B11, 'R', B12),
    % Black pieces (Ranks 6, 7, 8)
    set_nth1(42, B12, 'B', B13),
    set_nth1(44, B13, 'B', B14),
    set_nth1(46, B14, 'B', B15),
    set_nth1(48, B15, 'B', B16),
    set_nth1(49, B16, 'B', B17),
    set_nth1(51, B17, 'B', B18),
    set_nth1(53, B18, 'B', B19),
    set_nth1(55, B19, 'B', B20),
    set_nth1(58, B20, 'B', B21),
    set_nth1(60, B21, 'B', B22),
    set_nth1(62, B22, 'B', B23),
    set_nth1(64, B23, 'B', Board).

% ==== PLAYER LOGIC ====
current_player(state(_, Player, _), Player).

opponent('black', 'red').
opponent('red', 'black').

% ==== COORDINATE HELPERS ====
idx(R, F, I) :- I is (R-1)*8 + F.

get_coords(I, R, F) :-
    R is (I-1)//8 + 1,
    F is (I-1)mod 8 + 1.

% ==== MOVE LOGIC ====
piece_of_player('B', 'black').
piece_of_player('BK', 'black').
piece_of_player('R', 'red').
piece_of_player('RK', 'red').

is_king('BK').
is_king('RK').

% Black moves from top (Rank 8) to bottom (Rank 1), so delta is -1
% Red moves from bottom (Rank 1) to top (Rank 8), so delta is 1
direction('black', -1).
direction('red', 1).

is_jump(move(From, To)) :-
    get_coords(From, R1, _),
    get_coords(To, R2, _),
    abs(R1 - R2) =:= 2.

jumped_piece(From, To, JumpIdx) :-
    get_coords(From, R1, F1),
    get_coords(To, R2, F2),
    MidR is (R1 + R2) // 2,
    MidF is (F1 + F2) // 2,
    idx(MidR, MidF, JumpIdx).

simple_move_possible(Board, Player, From, To) :-
    nth1(From, Board, Piece),
    piece_of_player(Piece, Player),
    nth1(To, Board, '__'),
    get_coords(From, R1, F1),
    get_coords(To, R2, F2),
    abs(F1 - F2) =:= 1,
    abs(R1 - R2) =:= 1,
    (is_king(Piece) -> true ; (direction(Player, Dir), R2 is R1 + Dir)),
    (R1 + F1) mod 2 =:= (R2 + F2) mod 2.

jump_move_possible(Board, Player, From, To) :-
    nth1(From, Board, Piece),
    piece_of_player(Piece, Player),
    nth1(To, Board, '__'),
    get_coords(From, R1, F1),
    get_coords(To, R2, F2),
    abs(F1 - F2) =:= 2,
    abs(R1 - R2) =:= 2,
    (is_king(Piece) -> true ; (direction(Player, Dir), R2 is R1 + (Dir * 2))),
    jumped_piece(From, To, JumpIdx),
    nth1(JumpIdx, Board, OppPiece),
    piece_of_player(OppPiece, Opponent),
    opponent(Player, Opponent),
    (R1 + F1) mod 2 =:= (R2 + F2) mod 2.

legal_move(state(Board, Player, MustJump), move(From, To)) :-
    (MustJump \= 'none' ->
        From = MustJump,
        jump_move_possible(Board, Player, From, To)
    ;
        (   exists_jump(Board, Player) ->
            jump_move_possible(Board, Player, From, To)
        ;
            simple_move_possible(Board, Player, From, To)
        )
    ).

exists_jump(Board, Player) :-
    jump_move_possible(Board, Player, _, _).

% ==== APPLY MOVE ====
apply_move(state(Board, Player, _MustJump), move(From, To), NewState) :-
    nth1(From, Board, Piece),
    (is_jump(move(From, To)) ->
        jump_move_possible(Board, Player, From, To)
    ;
        simple_move_possible(Board, Player, From, To)
    ),
    set_nth1(From, Board, '__', B1),
    (   is_jump(move(From, To)) ->
        jumped_piece(From, To, JumpIdx),
        set_nth1(JumpIdx, B1, '__', B2)
    ;   B2 = B1
    ),
    get_coords(To, R2, _),
    (   (Player == 'black', R2 == 1) -> NewPiece = 'BK'
    ;   (Player == 'red', R2 == 8) -> NewPiece = 'RK'
    ;   NewPiece = Piece
    ),
    set_nth1(To, B2, NewPiece, FinalBoard),
    (   is_jump(move(From, To)) ->
        (   jump_move_possible(FinalBoard, Player, To, _) ->
            NewState = state(FinalBoard, Player, To)
        ;   opponent(Player, NextPlayer),
            NewState = state(FinalBoard, NextPlayer, 'none')
        )
    ;   opponent(Player, NextPlayer),
        NewState = state(FinalBoard, NextPlayer, 'none')
    ).

% ==== GAME OVER ====
game_over(State, Winner) :-
    current_player(State, Player),
    opponent(Player, Opponent),
    (   \+ legal_move(State, _) ->
        Winner = Opponent
    ;   State = state(Board, _, _),
        \+ has_pieces(Board, 'black'),
        Winner = 'red'
    ;   State = state(Board, _, _),
        \+ has_pieces(Board, 'red'),
        Winner = 'black'
    ).

has_pieces(Board, Player) :-
    nth1(_, Board, Piece),
    piece_of_player(Piece, Player).

% ==== RENDER STATE ====
render_state(state(Board, _, _)) :-
    write('  a b c d e f g h'), nl,
    render_rows(Board, 8).

render_rows(_, 0) :- !.
render_rows(Board, R) :-
    format('~w ', [R]),
    render_cols(Board, R, 1),
    nl,
    R1 is R - 1,
    render_rows(Board, R1).

render_cols(_, _, 9) :- !.
render_cols(Board, R, F) :-
    idx(R, F, I),
    nth1(I, Board, Piece),
    render_piece(Piece),
    F1 is F + 1,
    render_cols(Board, R, F1).

render_piece('__') :- write('. ').
render_piece('B') :- write('b ').
render_piece('BK') :- write('B ').
render_piece('R') :- write('r ').
render_piece('RK') :- write('R ').

% ==== QUERY REFERENCE ====
% initial_state(S).
% current_player(S, P).
% legal_move(S, M).
% apply_move(S, M, S2).
% game_over(S, W).
% render_state(S).

% ==== TEST QUERIES ====
% 1. Opening: initial_state(S), legal_move(S, M).
% 2. Sequence: initial_state(S), legal_move(S, M), apply_move(S, M, S2), render_state(S2).
% 3. Win:
%    B_Only = [ '__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','__','B','__','__','__','__','__','__','__'],
%    S_Win = state(B_Only, 'red', 'none'), game_over(S_Win, W).

% =============================================================================
% TEST SUITE
% Run these by calling: test_opening. test_movement. test_capture. test_kinging. test_win.
% =============================================================================

% 1. Test: Can the game start and find opening moves?
test_opening :-
    initial_state(S),
    (legal_move(S, M) ->
        format('Opening move found: ~w~n', [M]),
        writeln('SUCCESS: Opening moves are available.')
    ;   writeln('FAILURE: No opening moves found.')
    ).

% 2. Test: Does the turn switch after a move?
test_movement :-
    initial_state(S1),
    current_player(S1, P1),
    legal_move(S1, M),
    apply_move(S1, M, S2),
    current_player(S2, P2),
    (P1 \== P2 ->
        writeln('SUCCESS: Turn switched correctly.')
    ;   writeln('FAILURE: Turn did not switch.')
    ).

% 3. Test: Is jumping mandatory?
% Setup: Black at 33 (R5, F1), Red at 26 (R4, F2), Target at 19 (R3, F3)
test_capture :-
    Empty = [ '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__' ],
    set_nth1(33, Empty, 'B', B1),  % Black piece
    set_nth1(26, B1, 'R', B2),     % Red piece to jump
    set_nth1(19, B2, '__', Board), % Landing square
    S = state(Board, 'black', 'none'),
    % A jump should be legal: From 33 to 19
    (legal_move(S, move(33, 19)) -> JumpOk = true ; JumpOk = false),
    % A simple move should be ILLEGAL because jump is mandatory
    % Simple move from 33 to 26 is blocked by Red, so let's test 33 to 25 (if possible)
    % Actually, any move that isn't the jump should fail.
    (legal_move(S, move(33, 25)) -> SimpleOk = true ; SimpleOk = false),
    (JumpOk == true, SimpleOk == false ->
        writeln('SUCCESS: Mandatory jump rule enforced.')
    ;   format('FAILURE: JumpOk=~w, SimpleOk=~w~n', [JumpOk, SimpleOk])
    ).

% 4. Test: Does a piece promote to King?
% Setup: Black piece at Rank 2, File 2 (Index 10), moving to Rank 1, File 1 (Index 1)
test_kinging :-
    Empty = [ '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__' ],
    set_nth1(10, Empty, 'B', Board),
    S = state(Board, 'black', 'none'),
    apply_move(S, move(10, 1), S2),
    S2 = state(Board2, _, _),
    nth1(1, Board2, Piece),
    (Piece == 'BK' ->
        writeln('SUCCESS: Piece promoted to BK.')
    ;   writeln('FAILURE: Promotion failed.')
    ).

% 5. Test: Does game_over detect a win?
test_win :-
    Empty = [ '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              '__','__','__','__','__','__','__','__',
              'B','__','__','__','__','__','__','__'],
    S = state(Empty, 'red', 'none'),
    (game_over(S, 'black') ->
        writeln('SUCCESS: Win condition detected.')
    ;   writeln('FAILURE: Win condition not detected.')
    ).


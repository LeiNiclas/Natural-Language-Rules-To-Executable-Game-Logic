% ==== STANDARD CHECKERS (SWI-Prolog) ====
% Board representation: list of 64 atoms (index 1..64)
% Atoms: '__' (empty), 'B' (black man), 'BK' (black king), 'R' (red man), 'RK' (red king)
% State: state(Board, Player, _)
% Coordinate system:
%   index = row*8 + col + 1
%   row0: bottom (rank1), row7: top (rank8)
%   col0: a, col1: b, ... col7: h
%   Example: a1 -> index1 (row0,col0), h8 -> index64 (row7,col7)

%-------------------- Helper: set_nth1 (as required) --------------------
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

%-------------------- Board utilities --------------------
field_idx(I, F) :- F is ((I-1) mod 8).
rank_idx(I, R) :- R is ((I-1) // 8).

% black square condition (dark squares used in checkers)
black_square(I) :- field_idx(I, F), rank_idx(I, R), 0 is (F+R) mod 2.

piece_color(B, black).
piece_color(BK, black).
piece_color(R, red).
piece_color(RK, red).

piece_type(B, man).
piece_type(BK, king).
piece_type(R, man).
piece_type(RK, king).

% opponent
opponent(black, red).
opponent(red, black).

% piece at index
piece_at(Board, I, Piece) :- nth1(I, Board, Piece).

% empty square
empty_square(Board, I) :- piece_at(Board, I, '__').

% occupied by opponent
opp_piece_at(Board, I, Color) :-
    piece_at(Board, I, Piece),
    piece_color(Piece, OppColor),
    OppColor \= Color.

% add a piece to board (returns NewBoard)
add_piece(Board, Index, Piece, NewBoard) :-
    set_nth1(Index, Board, Piece, NewBoard).

% set multiple positions
set_positions(Board, [], _, Board).
set_positions(Board, [Idx|Ids], Piece, NewBoard) :-
    add_piece(Board, Idx, Piece, Temp),
    set_positions(Temp, Ids, Piece, NewBoard).

%-------------------- Initial board (from JSON) --------------------
initial_board(Board) :-
    % start with all empty
    length(Board, 64),
    maplist(=('__'), Board),
    % black men positions (from JSON: a7,c7,e7,g7,b6,d6,f6,h6,a5,c5,e5,g5)
    BlackPos = [49,51,53,55,42,44,46,48,33,35,37,39],
    set_positions(Board, BlackPos, 'B', B1),
    % red men positions (from JSON: b2,d2,f2,h2,a1,c1,e1,g1,b0,d0,f0,h0 -> treat b0 as b1, etc.)
    RedPos   = [10,12,14,16,1,3,5,7,2,4,6,8],
    set_positions(B1, RedPos, 'R', InitialBoard).

initial_state(state(InitialBoard, black, _)) :-
    initial_board(InitialBoard).

%-------------------- Turn handling --------------------
current_player(state(_, Player, _), Player).

next_player(black, red).
next_player(red, black).

%-------------------- Move generation --------------------
% Directions for men: black -1 row (toward bottom), red +1 row (toward top)
% Note: In our coordinate system, row increases upward (row0=bottom, row7=top)
% So black moves upward (toward row7) -> row+1, but since we store row0 at bottom,
% moving up means increasing row index. However, in the initial setup:
%   Black pieces are on rows 5,6,7 (which are indices 4,5,6 in 0-based row from bottom)
%   and they should move toward row 7 (top) -> increasing row index.
%   But in the JSON, black moves from a7 (row6) to a6 (row5) which is downward in the board but upward in our array?
%   Let me clarify:
%   Our array index:
%        row0: a1,b1,...,h1
%        row1: a2,b2,...,h2
%        ...
%        row7: a8,b8,...,h8
%   Black starts on row6 (a7 is at index 6*8+0+1=49) and should move to row5 (a6 is at index 5*8+0+1=41) -> decreasing row index.
%   Therefore, black moves in the negative row direction (toward lower row numbers).
%   Similarly, red starts on row1 (a2 is at index 1*8+0+1=10) and should move to row2 (a3 is at index 2*8+0+1=17) -> increasing row index.
%   So:
%        black: move in direction -1 (row decreases)
%        red: move in direction +1 (row increases)
%   This matches the original setup.

man_dir(black, -1).
man_dir(red, 1).

% King moves: all four diagonals
king_deltas([(-1,-1),(-1,1),(1,-1),(1,1)]).

% Legal move: either a simple step (if no jumps) or a jump
legal_move(state(Board, Player, _), move(From, To)) :-
    % piece belongs to player
    piece_at(Board, From, Piece),
    piece_color(Piece, Player),
    % generate possible jumps
    jump_moves(Board, Player, From, JumpToList),
    (   JumpToList = [] ->
        % no jumps -> simple moves
        simple_moves(Board, Player, From, SimpleList),
        member(To, SimpleList)
    ;   % jumps exist -> must jump
        member(To, JumpToList)
    ).

% Simple moves (one step)
simple_moves(Board, Player, From, Moves) :-
    piece_at(Board, From, Piece),
    (   piece_type(Piece, man) ->
        man_dir(Player, Dir),
        simple_man_moves(Dir, From, Cand)
    ;   piece_type(Piece, king) ->
        king_deltas(Deltas),
        simple_king_moves(Deltas, From, Cand)
    ),
    % filter to empty black squares
    include(empty_square(Board), Cand, Cand1),
    include(black_square, Cand1, Moves).

simple_man_moves(Dir, From, Cand) :-
    field_idx(From, F), rank_idx(From, R),
    F1 is F-1, F2 is F+1,
    R1 is R+Dir,
    (   (F1>=0, F1=<7, R1>=0, R1=<7) -> index_from_rc(F1,R1,To1) ; To1 = -1 ),
    (   (F2>=0, F2=<7, R1>=0, R1=<7) -> index_from_rc(F2,R1,To2) ; To2 = -1 ),
    exclude(=( -1), [To1,To2], Cand).

simple_king_moves(Deltas, From, Cand) :-
    field_idx(From, F), rank_idx(From, R),
    include(valid_king_step(F,R), Deltas, Steps),
    maplist(index_from_delta(F,R), Steps, Cand).

valid_king_step(F,R, (DF,DR)) :-
    NF is F+DF, NR is R+DR,
    NF >= 0, NF =< 7, NR >= 0, NR =< 7.

index_from_delta(F,R, (DF,DR), To) :-
    NF is F+DF, NR is R+DR,
    index_from_rc(NF,NR,To).

index_from_rc(F,R,Index) :- Index is R*8 + F + 1.

% Jump moves (must capture opponent)
jump_moves(Board, Player, From, Jumps) :-
    piece_at(Board, From, Piece),
    (   piece_type(Piece, man) ->
        man_dir(Player, Dir),
        jump_man_moves(Dir, Board, Player, From, Jumps)
    ;   piece_type(Piece, king) ->
        king_deltas(Deltas),
        jump_king_moves(Deltas, Board, Player, From, Jumps)
    ).

jump_man_moves(Dir, Board, Player, From, Jumps) :-
    field_idx(From, F), rank_idx(From, R),
    % left jump
    F1 is F-1, F2 is F-2,
    R1 is R+Dir, R2 is R+2*Dir,
    (   (F1>=0, F1=<7, R1>=0, R1=<7,
         F2>=0, F2=<7, R2>=0, R2=<7) ->
        jump_if(Board, Player, F1,R1, F2,R2, Jump1) ; Jump1 = [] ),
    % right jump
    F3 is F+1, F4 is F+2,
    (   (F3>=0, F3=<7, R1>=0, R1=<7,
         F4>=0, F4=<7, R2>=0, R2=<7) ->
        jump_if(Board, Player, F3,R1, F4,R2, Jump2) ; Jump2 = [] ),
    append(Jump1, Jump2, Jumps).

jump_king_moves(Deltas, Board, Player, From, Jumps) :-
    field_idx(From, F), rank_idx(From, R),
    include(jump_king_delta(F,R), Deltas, ValidDeltas),
    maplist(jump_if_king(Board,Player,F,R), ValidDeltas, JumpLists),
    append(JumpLists, Jumps).

jump_king_delta(F,R, (DF,DR)) :-
    NF is F+DF, NR is R+DR,
    NF2 is F+2*DF, NR2 is R+2*DR,
    NF >= 0, NF =< 7, NR >= 0, NR =< 7,
    NF2 >= 0, NF2 =< 7, NR2 >= 0, NR2 =< 7.

jump_if_king(Board,Player,F,R, (DF,DR), Jump) :-
    NF is F+DF, NR is R+DR,
    NF2 is F+2*DF, NR2 is R+2*DR,
    (   NF >= 0, NF =< 7, NR >= 0, NR =< 7,
        NF2 >= 0, NF2 =< 7, NR2 >= 0, NR2 =< 7 ->
            jump_if(Board,Player,NF,NR, NR2,NR2, Jump)
    ;   Jump = []
    ).

jump_if(Board,Player, F1,R1, F2,R2, Jump) :-
    index_from_rc(F1,R1,Mid),
    index_from_rc(F2,R2,Dst),
    piece_at(Board, Mid, MidPiece),
    piece_at(Board, Dst, DstPiece),
    piece_color(MidPiece, OppColor),
    OppColor \= Player,
    DstPiece = '__',
    black_square(Dst),
    Jump = [Dst].

%-------------------- Apply move --------------------
apply_move(state(Board, Player, _), move(From, To), state(NewBoard, NextPlayer, _)) :-
    piece_at(Board, From, Piece),
    piece_color(Piece, Player),
    % remove piece from From
    set_nth1(From, Board, '__', T1),
    % place piece at To (maybe promote)
    (   piece_type(Piece, man),
        rank_idx(To, R),
        (   Player = black, R = 0 -> KingPiece = 'BK'
        ;   Player = red,  R = 7 -> KingPiece = 'RK'
        ;   KingPiece = Piece
        ),
        set_nth1(To, T1, KingPiece, T2)
    ;   KingPiece = Piece,
        set_nth1(To, T1, Piece, T2)
    ),
    % if jump, remove captured piece
    (   jump_captured(Board, Player, From, To, Cap) ->
        set_nth1(Cap, T2, '__', NewBoard)
    ;   NewBoard = T2
    ),
    next_player(Player, NextPlayer).

jump_captured(Board, Player, From, To, Cap) :-
    piece_at(Board, From, Piece),
    field_idx(From, F1), rank_idx(From, R1),
    field_idx(To,   F2), rank_idx(To,   R2),
    DF is F2 - F1, DR is R2 - R1,
    abs(DF) =:= 2, abs(DR) =:= 2,
    MidF is F1 + DF//2,
    MidR is R1 + DR//2,
    index_from_rc(MidF, MidR, Cap),
    piece_at(Board, Cap, CapPiece),
    piece_color(CapPiece, OppColor),
    OppColor \= Player.

%-------------------- Game over --------------------
game_over(state(Board, Player, _), Winner) :-
    (   opponent(Player, Opp),
        \+ opp_piece_exists(Board, Opp) ->
            Winner = Player
    ;   \+ has_legal_move(state(Board, Player, _)) ->
        % no legal moves -> opponent wins
        opponent(Player, Opp),
        Winner = Opp
    ;   % otherwise game not over
        fail
    ).

opp_piece_exists(Board, Color) :-
    nth1(I, Board, Piece),
    piece_color(Piece, Color).

has_legal_move(state(Board, Player, _)) :-
    nth1(I, Board, Piece),
    piece_color(Piece, Player),
    legal_move(state(Board, Player, _), move(I, _)).

%-------------------- Render --------------------
render_state(state(Board, _, _)) :-
    format('  a b c d e f g h~n'),
    rank(7),
    nl.

rank(R) :-
    R >= 0,
    R1 is R - 1,
    format('~w|', [R+1]),
    file(0),
    format('|~w~n', [R+1]),
    rank(R1).
rank(-1).

file(F) :-
    F =< 7,
    F1 is F + 1,
    index_from_rc(F,R,Idx),
    nth1(Board, Idx, Piece),
    piece_symbol(Piece, Sym),
    format('~w ', [Sym]),
    file(F1).
file(_, 8).

piece_symbol('__', .).
piece_symbol('B', b).
piece_symbol('BK', B).
piece_symbol('R', r).
piece_symbol('RK', R).

%-------------------- Query reference --------------------
% ==== QUERY REFERENCE ====
% initial_state(S).
% current_state(S, P) :- current_state(S, P).
% legal_move(S, M) :- legal_move(S, M).
% apply_move(S, M, NS) :- apply_move(S, M, NS).
% game_over(S, W) :- game_over(S, W).
% render_state(S) :- render_state(S).

% ==== TEST SUITE ====
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
    S = state(Board, black, none),
    % A jump should be legal: From 33 to 19
    (legal_move(S, move(33, 19)) -> JumpOk = true ; JumpOk = false),
    % A simple move should be ILLEGAL because jump is mandatory
    % Simple move from 33 to 25 is blocked by empty? Actually 25 is empty but jump mandatory -> should fail
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
    S = state(Board, black, none),
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

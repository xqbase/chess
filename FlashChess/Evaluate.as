/*
Evaluate.as - Source Code for Flash Chess, Part IV

Flash Chess - a Chess Program for Web
Designed by Morning Yellow, Version: 1.0, Last Modified: Jul. 2008
Copyright (C) 2008 mobilechess.sourceforge.net

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

// This part is ported from Owl Chess Sample in Borland C++ 5.0
package {
	public class Evaluate {
		public static const PIECE_KING:int = Position.PIECE_KING;
		public static const PIECE_QUEEN:int = Position.PIECE_QUEEN;
		public static const PIECE_ROOK:int = Position.PIECE_ROOK;
		public static const PIECE_BISHOP:int = Position.PIECE_BISHOP;
		public static const PIECE_KNIGHT:int = Position.PIECE_KNIGHT;
		public static const PIECE_PAWN:int = Position.PIECE_PAWN;

		public static const FULL_BIT_RANK:int = 0x0ff0;
		public static const LAZY_MARGIN:int = 100;
		public static const ISOLATED_PENALTY:int = 10;
		public static const DOUBLE_PENALTY:int = 4;

		public static const cnPieceValue:Array = new Array(0, 9, 5, 3, 3, 1);

		public static const cnPassPawn:Array = new Array(0, 35, 30, 20, 10, 5, 0, 0);

		public static const cnDistance:Array = new Array(
								 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 7, 6, 7, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 7, 6, 5, 6, 7, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 7, 6, 5, 4, 5, 6, 7, 0, 0, 0, 0, 0,
			0, 0, 0, 7, 6, 5, 4, 3, 4, 5, 6, 7, 0, 0, 0, 0,
			0, 0, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, 0, 0, 0,
			0, 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 0, 0,
			7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 0,
			0, 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, 7, 0, 0,
			0, 0, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, 0, 0, 0,
			0, 0, 0, 7, 6, 5, 4, 3, 4, 5, 6, 7, 0, 0, 0, 0,
			0, 0, 0, 0, 7, 6, 5, 4, 5, 6, 7, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 7, 6, 5, 6, 7, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 7, 6, 7, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0
		);

		public static const cnEndgameEdge:Array = new Array(
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
		);

		public static const cnEndgameBottom:Array = new Array(
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
		);

		public static const cnEndgameKingPenalty:Array = new Array(
			0, 0, 0, 0,25,22,19,16,16,19,22,25, 0, 0, 0, 0,
			0, 0, 0, 0,17,14,11, 8, 8,11,14,17, 0, 0, 0, 0,
			0, 0, 0, 0,13,10, 7, 4, 4, 7,10,13, 0, 0, 0, 0,
			0, 0, 0, 0, 9, 6, 3, 0, 0, 3, 6, 9, 0, 0, 0, 0,
			0, 0, 0, 0, 9, 6, 3, 0, 0, 3, 6, 9, 0, 0, 0, 0,
			0, 0, 0, 0,13,10, 7, 4, 4, 7,10,13, 0, 0, 0, 0,
			0, 0, 0, 0,17,14,11, 8, 8,11,14,17, 0, 0, 0, 0,
			0, 0, 0, 0,25,22,19,16,16,19,22,25, 0, 0, 0, 0
		);

		public static const cnEdgePenalty:Array = new Array(
			0, 0, 0, 0, 6, 5, 4, 3, 3, 4, 5, 6, 0, 0, 0, 0,
			0, 0, 0, 0, 5, 4, 3, 2, 2, 3, 4, 5, 0, 0, 0, 0,
			0, 0, 0, 0, 4, 3, 2, 1, 1, 2, 3, 4, 0, 0, 0, 0,
			0, 0, 0, 0, 3, 2, 1, 0, 0, 1, 2, 3, 0, 0, 0, 0,
			0, 0, 0, 0, 3, 2, 1, 0, 0, 1, 2, 3, 0, 0, 0, 0,
			0, 0, 0, 0, 4, 3, 2, 1, 1, 2, 3, 4, 0, 0, 0, 0,
			0, 0, 0, 0, 5, 4, 3, 2, 2, 3, 4, 5, 0, 0, 0, 0,
			0, 0, 0, 0, 6, 5, 4, 3, 3, 4, 5, 6, 0, 0, 0, 0
		);

		public static const cnPawnValue:Array = new Array(
			0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0, 0, 0, 0, 0,
			0, 0, 0, 0, 30, 30, 46, 70, 78, 46, 30, 30, 0, 0, 0, 0,
			0, 0, 0, 0,  8,  8, 22, 43, 50, 22,  8,  8, 0, 0, 0, 0,
			0, 0, 0, 0,  4,  4, 16, 34, 40, 16,  4,  4, 0, 0, 0, 0,
			0, 0, 0, 0,  2,  2, 12, 27, 32, 12,  2,  2, 0, 0, 0, 0,
			0, 0, 0, 0,  0,  0,  8, 20, 24,  8,  0,  0, 0, 0, 0, 0,
			0, 0, 0, 0,  0,  0,  6, 15, 18,  6,  0,  0, 0, 0, 0, 0,
			0, 0, 0, 0,  0,  0,  0,  0,  0,  0,  0,  0, 0, 0, 0, 0
		);

		public static const cnCenterImportance:Array = new Array(
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 2, 5, 5, 2, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 2, 5, 8, 8, 5, 2, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 2, 5, 8, 8, 5, 2, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 2, 5, 5, 2, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		);

		public static const cnRankDistance:Array = new Array(
			0, 0, 0, 0,12,12,12,12,12,12,12,12, 0, 0, 0, 0,
			0, 0, 0, 0,12,12,12,12,12,12,12,12, 0, 0, 0, 0,
			0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0,
			0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		);

		public static function IN_BOARD(sq:int):Boolean {
			return Position.IN_BOARD(sq);
		}

		public static function SQUARE_FLIP(sq:int):int {
			return Position.SQUARE_FLIP(sq);
		}

		public static function losingKingValue(sq:int):int {
			return -cnEndgameKingPenalty[sq] * 2 - cnEndgameBottom[sq] * 8;
		}

		public static function winningKingValue(sq:int, sqOppKing:int):int {
			return -cnDistance[sqOppKing - sq + 128] * 2 - cnEndgameEdge[sq] * 8;
		}

		public static function calcSlideControl(pos:Position, sqSrc:int, vlAttack:Array, bIsRook:Boolean):int {
			var vlControl:int = 0;
			var i:int;
			for (i = 0; i < 4; i ++) {
				var nDelta:int = (bIsRook ? Position.cnRookDelta[i] : Position.cnBishopDelta[i]);
				var sqDst:int = sqSrc + nDelta;
				var bDirect:Boolean = true;
				while (IN_BOARD(sqDst)) {
					vlControl += (bDirect ? vlAttack[sqDst] : int(vlAttack[sqDst] / 2));
					if (pos.pcSquares[sqDst] > 0) {
						var nPieceType:int = Position.PIECE_TYPE(pos.pcSquares[sqDst]);
						if (nPieceType == PIECE_PAWN) {
							break;
						} else if (nPieceType == PIECE_KING || nPieceType == PIECE_KNIGHT ||
								nPieceType == (bIsRook ? PIECE_BISHOP : PIECE_ROOK)) {
							bDirect = false;
						}
					}
					sqDst += nDelta;
				}
			}
			return vlControl;
		}

		public static function calcRookControl(pos:Position, sqSrc:int, vlAttack:Array):int {
			return calcSlideControl(pos, sqSrc, vlAttack, true);
		}

		public static function calcBishopControl(pos:Position, sqSrc:int, vlAttack:Array):int {
			return calcSlideControl(pos, sqSrc, vlAttack, false);
		}

		public static function preEval(pos:Position):void {
			// 1. Calculate Simple Materials for Both Sides
			var vlWhite:int = 0, vlBlack:int = 0, sqWhiteKing:int = 0, sqBlackKing:int = 0;
			var i:int, sq:int, pc:int;
			for (sq = 0; sq < 128; sq ++) {
				pc = pos.pcSquares[sq];
				if (pc == 0) {
					continue;
				}
				if (pc < 16) {
					vlWhite += cnPieceValue[pc - 8];
					if (pc == 8) {
						sqWhiteKing = sq;
					}
				} else {
					vlBlack += cnPieceValue[pc - 16];
					if (pc == 16) {
						sqBlackKing = sq;
					}
				}
			}
			var inEndgame:Boolean = Util.min(vlWhite, vlBlack) <= 6 && Util.abs(vlWhite - vlBlack) >= 2;
			// 2. Calculate Attacking Values for Each Squares (Both Sides)
			var vlWhiteAttack:Array = new Array(128), vlBlackAttack:Array = new Array(128);
			for (sq = 0; sq < 128; sq ++) {
				vlWhiteAttack[sq] = vlBlackAttack[SQUARE_FLIP(sq)] =
						int(cnRankDistance[sq] * Util.max(vlWhite + vlBlack - 24, 8) / 32) + cnCenterImportance[sq];
			}
			for (i = 0; i < 8; i ++) {
				var vlImportance:int = int(12 * Util.max(vlWhite + vlBlack - 24, 8) / 32);
				sq = sqWhiteKing + Position.cnKingDelta[i];
				if (IN_BOARD(sq)) {
					vlBlackAttack[sq] += vlImportance;
				}
				sq = sqBlackKing + Position.cnKingDelta[i];
				if (IN_BOARD(sq)) {
					vlWhiteAttack[sq] += vlImportance;
				}
			}
			// 3. Calculate Control Table for Each Squares
			var vlWhiteRookControl:Array = new Array(128), vlWhiteBishopControl:Array = new Array(128);
			var vlBlackRookControl:Array = new Array(128), vlBlackBishopControl:Array = new Array(128);
			for (sq = 0; sq < 128; sq ++) {
				if (IN_BOARD(sq)) {
					vlWhiteRookControl[sq] = calcRookControl(pos, sq, vlWhiteAttack);
					vlBlackRookControl[sq] = calcRookControl(pos, sq, vlBlackAttack);
					vlWhiteBishopControl[sq] = calcBishopControl(pos, sq, vlWhiteAttack);
					vlBlackBishopControl[sq] = calcBishopControl(pos, sq, vlBlackAttack);
				}
			}
			// 4. Calculate Piece Value Table for Each Squares and Each Piece-Types
			for (sq = 0; sq < 128; sq ++) {
				if (!IN_BOARD(sq)) {
					continue;
				}
				var vlEdgePenalty:int = cnEdgePenalty[sq];
				if (inEndgame) {
					if (vlWhite < vlBlack) {
						// 4.1. In Endgames, the Losing King should be Close to Center and Distant to Bottom
						pos.vlWhitePiecePos[PIECE_KING][sq] = losingKingValue(sq);
						// 4.2. In Endgames, the Winning King should be Close to the Losing King and Distant to Border
						pos.vlBlackPiecePos[PIECE_KING][sq] = winningKingValue(sq, sqWhiteKing);
					} else {
						// 4.1. ...
						pos.vlBlackPiecePos[PIECE_KING][sq] = losingKingValue(sq);
						// 4.2. ...
						pos.vlWhitePiecePos[PIECE_KING][sq] = winningKingValue(sq, sqBlackKing);
					}
					// 4.3. In Endgames, Other Pieces are independent to their Positions
					for (i = PIECE_QUEEN; i <= PIECE_KNIGHT; i ++) {
						pos.vlWhitePiecePos[i][sq] = pos.vlBlackPiecePos[i][sq] =
								int(cnPieceValue[i] * 100);
					}
				} else {
					// 4.4. King should be Close to Center in Midgames or Endgames
					if (vlWhite + vlBlack <= 32) {
						pos.vlWhitePiecePos[PIECE_KING][sq] =
								pos.vlBlackPiecePos[PIECE_KING][sq] = -vlEdgePenalty;
					} else {
						pos.vlWhitePiecePos[PIECE_KING][sq] =
								pos.vlBlackPiecePos[PIECE_KING][sq] = 0;
					}
					// 4.5. Queen, Rook, Bishop should Favor their Control Values
					pos.vlWhitePiecePos[PIECE_QUEEN][sq] =
							int(cnPieceValue[PIECE_QUEEN] * 100 + (vlWhiteRookControl[sq] + vlWhiteBishopControl[sq]) / 8);
					pos.vlBlackPiecePos[PIECE_QUEEN][sq] =
							int(cnPieceValue[PIECE_QUEEN] * 100 + (vlBlackRookControl[sq] + vlBlackBishopControl[sq]) / 8);
					pos.vlWhitePiecePos[PIECE_ROOK][sq] =
							int(cnPieceValue[PIECE_ROOK] * 100 + int(vlWhiteRookControl[sq] / 2));
					pos.vlBlackPiecePos[PIECE_ROOK][sq] =
							int(cnPieceValue[PIECE_ROOK] * 100 + int(vlBlackRookControl[sq] / 2));
					pos.vlWhitePiecePos[PIECE_BISHOP][sq] =
							int(cnPieceValue[PIECE_BISHOP] * 100 + int(vlWhiteBishopControl[sq] / 2));
					pos.vlBlackPiecePos[PIECE_BISHOP][sq] =
							int(cnPieceValue[PIECE_BISHOP] * 100 + int(vlBlackBishopControl[sq] / 2));
					// 4.6. Knight should Favor its Attack Value
					var vlWhiteKnightAttack:int = 0, vlBlackKnightAttack:int = 0;
					for (i = 0; i < 8; i ++) {
						var sqDst:int = sq + Position.cnKnightDelta[i];
						if (IN_BOARD(sqDst)) {
							vlWhiteKnightAttack += vlWhiteAttack[sqDst];
							vlBlackKnightAttack += vlBlackAttack[sqDst];
						}
					}
					pos.vlWhitePiecePos[PIECE_KNIGHT][sq] =
							int(cnPieceValue[PIECE_KNIGHT] * 100 + int(vlWhiteKnightAttack / 4) - int(vlEdgePenalty * 3 / 2));
					pos.vlBlackPiecePos[PIECE_KNIGHT][sq] =
							int(cnPieceValue[PIECE_KNIGHT] * 100 + int(vlBlackKnightAttack / 4) - int(vlEdgePenalty * 3 / 2));
				}
				// 4.7. Pawn should Favor its Position Value
				pos.vlWhitePiecePos[PIECE_PAWN][sq] = pos.vlBlackPiecePos[PIECE_PAWN][SQUARE_FLIP(sq)] =
						int(cnPieceValue[PIECE_PAWN] * 100 + int(cnPawnValue[sq] / 2) - 6);
			}
			/* 5. Calculate Piece Value Table for Pawn Structure
			 * 
			 * Self:
			 *   x P x - P = brForward,    x = brLeftCover/brRightCover
			 * ^ x P x - P = brSelf,       x = brSide
			 * | x P x - P = brSelf(Last), x = brChain
			 * 
			 * Opponent:
			 *   . . .
			 * ^ . x . - x = brOppPass, or BehindOppPass if a Pawn in Front
			 * | o o o - o = ~brSelf/brSide(Last)
			 */
			var sd:int;
			for (sd = 0; sd < 2; sd ++) {
				var brSelf:int = 0, brSide:int = 0, brBehindOppPass:int = 0;
				var brOppPass:int = FULL_BIT_RANK;
				for (i = 1; i <= 6; i ++) {
					var y:int = (sd == 0 ? 7 - i : i);
					var brOpp:int = (sd == 0 ? pos.brBlackPawn[y] : pos.brWhitePawn[y]);
					brOppPass &= ~(brSelf | brSide);
					brBehindOppPass |= (brOppPass & brOpp);
					var brChain:int = brSide;
					brSelf = (sd == 0 ? pos.brWhitePawn[y] : pos.brBlackPawn[y]);
					brSide = ((brSelf >> 1) | (brSelf << 1)) & FULL_BIT_RANK;
					var brForward:int = (sd == 0 ? pos.brWhitePawn[y + 1] : pos.brBlackPawn[y + 1]);
					var brLeftCover:int = (brForward >> 1) & FULL_BIT_RANK;
					var brRightCover:int = (brForward << 1) & FULL_BIT_RANK;
					var x:int;
					for (x = Position.FILE_LEFT; x <= Position.FILE_RIGHT; x ++) {
						sq = Position.COORD_XY(x, y);
						var brSquare:int = 1 << x;
						// 5.1. Bonus for Parallel and Protected Pawns
						var vl:int = ((brSide & brSquare) != 0 ? 3 : 0) + ((brChain & brSquare) != 0 ? 2 : 0);
						// 5.2. Bonus for the Pawn which can Protect Other Pawns
						vl += ((brLeftCover & brSquare) != 0 ? 2 : 0) + ((brRightCover & brSquare) != 0 ? 2 : 0);
						// 5.3. Bonus for Self (Penalty for Moving)
						vl += ((brSelf & brSquare) != 0 ? 1 : 0);
						if (sd == 0) {
							pos.vlWhitePiecePos[PIECE_PAWN][sq] += vl;
						} else {
							pos.vlBlackPiecePos[PIECE_PAWN][sq] += vl;
						}
						if (vlWhite + vlBlack <= 32) {
							// 5.4. Bonus for Passed Pawn
							if ((brOppPass & brSquare) != 0) {
								if (sd == 0) {
									pos.vlBlackPiecePos[PIECE_PAWN][sq] += cnPassPawn[i];
								} else {
									pos.vlWhitePiecePos[PIECE_PAWN][sq] += cnPassPawn[i];
								}
							}
							// 5.5. Bonus for Rook (Both Sides) Behind Pawn
							if ((brBehindOppPass & brSquare) != 0) {
								pos.vlWhitePiecePos[PIECE_ROOK][sq] += 8;
								pos.vlBlackPiecePos[PIECE_ROOK][sq] += 8;
								if (i == 6) {
									var sqBottom:int = sq + Position.FORWARD_DELTA(sd);
									pos.vlWhitePiecePos[PIECE_ROOK][sqBottom] += 8;
									pos.vlBlackPiecePos[PIECE_ROOK][sqBottom] += 8;
								}
							}
						}
					}
				}
			}
			// 6. Calculate Penalty for Blocking Center Pawns with a Bishop
			for (sq = 0x67; sq <= 0x68; sq ++) {
				if (pos.pcSquares[sq] == 8 + PIECE_PAWN) {
					pos.vlWhitePiecePos[PIECE_BISHOP][sq - 16] -= 10;
				}
			}
			for (sq = 0x17; sq <= 0x18; sq ++) {
				if (pos.pcSquares[sq] == 16 + PIECE_PAWN) {
					pos.vlBlackPiecePos[PIECE_BISHOP][sq + 16] -= 10;
				}
			}
			// 7. Update "vlWhite" and "vlBlack" in "pos"
			pos.vlWhite = pos.vlBlack = 0;
			for (sq = 0; sq < 128; sq ++) {
				pc = pos.pcSquares[sq];
				if (pc > 0) {
					if (pc < 16) {
						pos.vlWhite += pos.vlWhitePiecePos[pc - 8][sq];
					} else {
						pos.vlBlack += pos.vlBlackPiecePos[pc - 16][sq];
					}
				}
			}
		}

		private static var xxx:int = 0;

		public static function evaluate(pos:Position, vlAlpha:int, vlBeta:int):int {
			// 1. Material (with Position) Value
			var vl:int = pos.material();
			if (vl + LAZY_MARGIN <= vlAlpha) {
				return vl + LAZY_MARGIN;
			} else if (vl - LAZY_MARGIN >= vlBeta) {
				return vl - LAZY_MARGIN;
			}
			// 2. Pawn Structure Value
			var sd:int;
			for (sd = 0; sd < 2; sd ++) {
				var brSingle:int = 0, brDouble:int = 0;
				var brs:Array = (sd == 0 ? pos.brWhitePawn : pos.brBlackPawn);
				var i:int;
				for (i = 1; i <= 6; i ++) {
					brDouble |= brSingle & brs[i];
					brSingle |= brs[i];
				}
				var brIsolated:int = brSingle & ~((brSingle << 1) | (brSingle >> 1));
				var vlPenalty:int = Util.POP_COUNT_16(brDouble) * DOUBLE_PENALTY +
						Util.POP_COUNT_16(brIsolated) * ISOLATED_PENALTY +
						Util.POP_COUNT_16(brIsolated & brDouble) * ISOLATED_PENALTY * 2;
				vl += (pos.sdPlayer == sd ? -vlPenalty : vlPenalty);
			}
			return vl;
		}
	}
}
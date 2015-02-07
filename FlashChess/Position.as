/*
Position.as - Source Code for Flash Chess, Part I

Flash Chess - a Chess Program for Web
Designed by Morning Yellow, Version: 1.12, Last Modified: May 2010
Copyright (C) 2008-2010 mobilechess.sourceforge.net

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

package {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.Endian;

	public class Position {
		public static const MATE_VALUE:int = 10000;
		public static const BAN_VALUE:int = MATE_VALUE - 100;
		public static const WIN_VALUE:int = MATE_VALUE - 200;
		public static const NULL_SAFE_MARGIN:int = 1000;
		public static const NULL_OKAY_MARGIN:int = 500;
		public static const DRAW_VALUE:int = 50;
		public static const ADVANCED_VALUE:int = 10;

		public static const MAX_MOVE_NUM:int = 256;
		public static const MAX_GEN_MOVES:int = 128;
		// public static const MAX_BOOK_SIZE:int = 16384;

		public static const PIECE_KING:int = 0;
		public static const PIECE_QUEEN:int = 1;
		public static const PIECE_ROOK:int = 2;
		public static const PIECE_BISHOP:int = 3;
		public static const PIECE_KNIGHT:int = 4;
		public static const PIECE_PAWN:int = 5;

		public static const DIFF_LINE:int = 0;
		public static const SAME_RANK:int = 1;
		public static const SAME_FILE:int = 2;
		public static const SAME_DIAG_A1H8:int = 3;
		public static const SAME_DIAG_A8H1:int = 4;

		public static const RANK_TOP:int = 0;
		public static const RANK_BOTTOM:int = 7;
		public static const FILE_LEFT:int = 4;
		public static const FILE_RIGHT:int = 11;

		public static const DEL_PIECE:Boolean = true;

		private static const cnLegalSpan:Array = new Array(
								 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0
		);

		private static const cnSameLine:Array = new Array(
								 0, 0, 0, 0, 0, 0, 0, 0, 0,
			4, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 3, 0,
			0, 4, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0,
			0, 0, 4, 0, 0, 0, 0, 2, 0, 0, 0, 0, 3, 0, 0, 0,
			0, 0, 0, 4, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 0,
			0, 0, 0, 0, 4, 0, 0, 2, 0, 0, 3, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 4, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 4, 2, 3, 0, 0, 0, 0, 0, 0, 0,
			1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0,
			0, 0, 0, 0, 0, 0, 3, 2, 4, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 3, 0, 2, 0, 4, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 3, 0, 0, 2, 0, 0, 4, 0, 0, 0, 0, 0,
			0, 0, 0, 3, 0, 0, 0, 2, 0, 0, 0, 4, 0, 0, 0, 0,
			0, 0, 3, 0, 0, 0, 0, 2, 0, 0, 0, 0, 4, 0, 0, 0,
			0, 3, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 4, 0, 0,
			3, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 4, 0,
			0, 0, 0, 0, 0, 0, 0
		);

		private static const cnPawnLine:Array = new Array(
			0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0,
			0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0,
			0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0,
			0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
			0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
		);

		public static const cnKingDelta:Array = new Array(
			-17, -16, -15, -1, 1, 15, 16, 17
		);
		public static const cnRookDelta:Array = new Array(
			-16, -1, 1, 16
		);
		public static const cnBishopDelta:Array = new Array(
			-17, -15, 15, 17
		);
		public static const cnKnightDelta:Array = new Array(
			-33, -31, -18, -14, 14, 18, 31, 33
		);
		public static const cnMvvValue:Array = new Array(
			0, 900, 500, 300, 300, 100
		);
		public static const cnCastlingDirection:Array = new Array(1, -1, 1, -1);
		public static const csqCastlingKingSrc:Array = new Array(0x78, 0x78, 0x08, 0x08);
		public static const csqCastlingRookDst:Array = new Array(0x79, 0x77, 0x09, 0x07);
		public static const csqCastlingKingDst:Array = new Array(0x7a, 0x76, 0x0a, 0x06);
		public static const csqCastlingRookSrc:Array = new Array(0x7b, 0x74, 0x0b, 0x04);

		public static function IN_BOARD(sq:int):Boolean {
			return ((sq - 4) & 0x88) == 0;
		}

		public static function RANK_Y(sq:int):int {
			return sq >> 4;
		}

		public static function FILE_X(sq:int):int {
			return sq & 15;
		}

		public static function COORD_XY(x:int, y:int):int {
			return x + (y << 4);
		}

		public static function SQUARE_FLIP(sq:int):int {
			return 127 - sq;
		}

		public static function SQUARE_FORWARD(sq:int, sd:int):int {
			return sq - 16 + (sd << 5);
		}

		public static function FORWARD_DELTA(sd:int):int {
			return (sd << 5) - 16;
		}

		public static function PAWN_INIT(sq:int, sd:int):Boolean {
			return cnPawnLine[sq] == sd + 1;
		}

		public static function PAWN_PROMOTION(sq:int, sd:int):Boolean {
			return cnPawnLine[sq] == sd + 3;
		}

		public static function PAWN_EN_PASSANT(sq:int, sd:int):Boolean {
			return cnPawnLine[sq] == sd + 5;
		}

		public static function KING_SPAN(sqSrc:int, sqDst:int):Boolean {
			return cnLegalSpan[sqDst - sqSrc + 128] == 1;
		}

		public static function KNIGHT_SPAN(sqSrc:int, sqDst:int):Boolean {
			return cnLegalSpan[sqDst - sqSrc + 128] == 2;
		}

		public static function SAME_LINE(sqSrc:int, sqDst:int):int {
			return cnSameLine[sqDst - sqSrc + 128];
		}

		public static function CASTLING_TYPE(sd:int, sqSrc:int, sqDst:int):int {
			return (sd << 1) + (sqDst > sqSrc ? 0 : 1);
		}

		public static function SIDE_TAG(sd:int):int {
			return 8 + (sd << 3);
		}

		public static function OPP_SIDE_TAG(sd:int):int {
			return 16 - (sd << 3);
		}

		public static function SRC(mv:int):int {
			return mv & 127;
		}

		public static function DST(mv:int):int {
			return mv >> 7;
		}

		public static function MOVE(sqSrc:int, sqDst:int):int {
			return sqSrc + (sqDst << 7);
		}

		public static function PIECE_TYPE(pc:int):int {
			return pc & 7;
		}

		public static function MVV_LVA(pc:int, nLva:int):int {
			return cnMvvValue[pc & 7] - nLva;
		}

		public static var dwKeyPlayer:uint;
		public static var dwLockPlayer:uint;
		public static var dwKeyTable:Array = new Array(12);
		public static var dwLockTable:Array = new Array(12);

		public static var nBookSize:int = -1;
		public static var dwBookLock:Array;
		public static var mvBook:Array;
		public static var vlBook:Array;

		private static var stream:URLStream = new URLStream();

		private static function loadBook(e:Event):void {
			var n:int = stream.bytesAvailable / 8;
			dwBookLock = new Array(n);
			mvBook = new Array(n);
			vlBook = new Array(n);
			var i:int;
			for (i = 0; i < n; i ++) {
				dwBookLock[i] = stream.readUnsignedInt();
				mvBook[i] = stream.readUnsignedShort();
				vlBook[i] = stream.readUnsignedShort();
			}
			nBookSize = n;
		}

		private static function noBook(e:Event):void {
			nBookSize = 0;
		}

		private static function clinit():Object {
			var rc4:RC4 = new RC4(new Array(0, 0));
			dwKeyPlayer = rc4.nextLong();
			rc4.nextLong(); // Skip ZobristLock0
			dwLockPlayer = rc4.nextLong();
			var i:int, j:int;
			for (i = 0; i < 12; i ++) {
				dwKeyTable[i] = new Array(128);
				dwLockTable[i] = new Array(128);
				for (j = 0; j < 128; j ++) {
					dwKeyTable[i][j] = rc4.nextLong();
					rc4.nextLong(); // Skip ZobristLock0
					dwLockTable[i][j] = rc4.nextLong();
				}
			}

			stream.endian = Endian.LITTLE_ENDIAN;
			stream.addEventListener(Event.COMPLETE, loadBook);
			stream.addEventListener(IOErrorEvent.IO_ERROR, noBook);
			stream.load(new URLRequest("BOOK.DAT"));
			return null;
		}

		private static const _clinit_:Object = clinit();

		public var sdPlayer:int;
		public var pcSquares:Array = new Array(128);

		public var dwKey:uint, dwLock:uint;
		public var vlWhite:int, vlBlack:int;
		public var nMoveNum:int, nDistance:int;

		public var mvList:Array = new Array(MAX_MOVE_NUM);
		public var pcList:Array = new Array(MAX_MOVE_NUM);
		public var dwKeyList:Array = new Array(MAX_MOVE_NUM);
		public var bCheckList:Array = new Array(MAX_MOVE_NUM);
		public var bSpecialMoveList:Array = new Array(MAX_MOVE_NUM);
		public var nCastlingBitsList:Array = new Array(MAX_MOVE_NUM);
		public var sqEnPassantList:Array = new Array(MAX_MOVE_NUM);

		public var brWhitePawn:Array = new Array(8); // br = Bit-Rank
		public var brBlackPawn:Array = new Array(8); // br = Bit-Rank
		public var vlWhitePiecePos:Array = new Array(6);
		public var vlBlackPiecePos:Array = new Array(6);

		public function Position() {
			var i:int;
			for (i = 0; i < 6; i ++) {
				vlWhitePiecePos[i] = new Array(128);
				vlBlackPiecePos[i] = new Array(128);
			}
		}

		public function clearBoard():void {
			sdPlayer = 0;
			var sq:int;
			for (sq = 0; sq < 128; sq ++) {
				pcSquares[sq] = 0;
			}
			var i:int;
			for (i = 0; i < 8; i ++) {
				brWhitePawn[i] = brBlackPawn[i] = 0;
			}
			dwKey = dwLock = 0;
			vlWhite = vlBlack = 0;
		}

		public function captured():Boolean {
			return pcList[nMoveNum - 1] > 0;
		}

		public function inCheck():Boolean {
			return bCheckList[nMoveNum - 1];
		}

		public function specialMove():Boolean {
			return bSpecialMoveList[nMoveNum - 1];
		}

		public function castlingBits():int {
			return nCastlingBitsList[nMoveNum - 1];
		}

		public function enPassantSquare():int {
			return sqEnPassantList[nMoveNum - 1];
		}

		public function canCastling(nCastling:int):Boolean {
			if (!inCheck() && (castlingBits() & (1 << nCastling)) != 0) {
				var nDelta:int = cnCastlingDirection[nCastling];
				var sqSrc:int = csqCastlingKingSrc[nCastling] + nDelta;
				var sqDst:int = csqCastlingRookSrc[nCastling];
				while (sqSrc != sqDst) {
					if (pcSquares[sqSrc] > 0) {
						return false;
					}
					sqSrc += nDelta;
				}
				return !squareChecked(csqCastlingRookDst[nCastling]);
			}
			return false;
		}

		public function setIrrevEx(nCastlingBits:int, sqEnPassant:int):void {
			mvList[0] = pcList[0] = 0;
			nCastlingBitsList[0] = nCastlingBits;
			sqEnPassantList[0] = sqEnPassant;
			bCheckList[0] = checked();
			nMoveNum = 1;
			nDistance = 0;
		}

		public function setIrrev():void {
			setIrrevEx(castlingBits(), enPassantSquare());
		}

		public function addPiece(sq:int, pc:int, bDel:Boolean = false):void {
			var pcAdjust:int;
			pcSquares[sq] = bDel ? 0 : pc;
			if (pc < 16) {
				if (pc == 8 + PIECE_PAWN) {
					brWhitePawn[RANK_Y(sq)] ^= 1 << FILE_X(sq);
				}
				pcAdjust = pc - 8;
				vlWhite += bDel ? -vlWhitePiecePos[pcAdjust][sq] : vlWhitePiecePos[pcAdjust][sq];
			} else {
				if (pc == 16 + PIECE_PAWN) {
					brBlackPawn[RANK_Y(sq)] ^= 1 << FILE_X(sq);
				}
				pcAdjust = pc - 16;
				vlBlack += bDel ? -vlBlackPiecePos[pcAdjust][sq] : vlBlackPiecePos[pcAdjust][sq];
				pcAdjust += 6;
			}
			dwKey ^= dwKeyTable[pcAdjust][sq];
			dwLock ^= dwLockTable[pcAdjust][sq];
		}

		/* A - Take out Captured Piece (Different in En-Passant, see A-EP)
		 * B - Remove Source
		 * C - Add into Destination (Different in Promotion, see C-P)
		 * D - for Castling only
		 */
		public function movePiece():void {
			var sqSrc:int = SRC(mvList[nMoveNum]);
			var sqDst:int = DST(mvList[nMoveNum]);
			var pcCaptured:int = pcSquares[sqDst];
			if (pcCaptured > 0) {
				addPiece(sqDst, pcCaptured, DEL_PIECE); // A
			}
			var pc:int = pcSquares[sqSrc];
			// __ASSERT((pcCaptured & SIDE_TAG(sdPlayer)) == 0);
			// __ASSERT((pc & SIDE_TAG(sdPlayer)) != 0);
			addPiece(sqSrc, pc, DEL_PIECE); // B
			addPiece(sqDst, pc); // C
			pcList[nMoveNum] = pcCaptured;
			bSpecialMoveList[nMoveNum] = false;
			nCastlingBitsList[nMoveNum] = castlingBits();
			sqEnPassantList[nMoveNum] = 0;
			// CASTLING -> Set Castling Bits for Rook's Capture
			var nCastling:int;
			if (PIECE_TYPE(pcCaptured) == PIECE_ROOK) {
				nCastling = (1 - sdPlayer) << 1;
				if (sqDst == csqCastlingRookSrc[nCastling]) {
					nCastlingBitsList[nMoveNum] &= ~(1 << nCastling);
				} else if (sqDst == csqCastlingRookSrc[nCastling + 1]) {
					nCastlingBitsList[nMoveNum] &= ~(1 << (nCastling + 1));
				}
			}
			if (PIECE_TYPE(pc) == PIECE_KING) {
				// CASTLING -> Move both King and Rook
				if (!KING_SPAN(sqSrc, sqDst)) {
					nCastling = CASTLING_TYPE(sdPlayer, sqSrc, sqDst);
					addPiece(csqCastlingRookSrc[nCastling], pc - PIECE_KING + PIECE_ROOK, DEL_PIECE); // D
					addPiece(csqCastlingRookDst[nCastling], pc - PIECE_KING + PIECE_ROOK); // D
					bSpecialMoveList[nMoveNum] = true;
				}
				// CASTLING -> Set Castling Bits for King's Move
				nCastlingBitsList[nMoveNum] &= ~(3 << (sdPlayer << 1));
			} else if (PIECE_TYPE(pc) == PIECE_PAWN) {
				if (PAWN_PROMOTION(sqDst, sdPlayer)) {
					// PROMOTION -> Add a Queen instead of a Pawn
					addPiece(sqDst, pc, DEL_PIECE); // C-P
					addPiece(sqDst, pc - PIECE_PAWN + PIECE_QUEEN); // C-P
					bSpecialMoveList[nMoveNum] = true;
				} else if (sqDst == enPassantSquare()) {
					// EN-PASSANT -> Reset the Captured Piece for En-Passant Move
					var sqCaptured:int = sqDst - FORWARD_DELTA(sdPlayer);
					pcCaptured = pcSquares[sqCaptured];
					// __ASSERT(sqSrc == sqCaptured + 1 || sqSrc == sqCaptured - 1);
					// __ASSERT(pcCaptured == OPP_SIDE_TAG(sdPlayer) + PIECE_PAWN);
					addPiece(sqCaptured, pcCaptured, DEL_PIECE); // A-EP
					pcList[nMoveNum] = pcCaptured;
					bSpecialMoveList[nMoveNum] = true;
				} else {
					// EN-PASSANT -> Set En-Passant Square for Pawn's Double-Move
					var nDelta:int = FORWARD_DELTA(sdPlayer);
					if (sqDst == sqSrc + (nDelta << 1)) {
						sqEnPassantList[nMoveNum] = sqSrc + nDelta;
					}
				}
			} else if (PIECE_TYPE(pc) == PIECE_ROOK) {
				// CASTLING -> Set Castling Bits for Rook's Move
				nCastling = sdPlayer << 1;
				if (sqSrc == csqCastlingRookSrc[nCastling]) {
					nCastlingBitsList[nMoveNum] &= ~(1 << nCastling);
				} else if (sqSrc == csqCastlingRookSrc[nCastling + 1]) {
					nCastlingBitsList[nMoveNum] &= ~(1 << (nCastling + 1));
				}
			}
		}

		/* A - Return Captured Piece (Different in En-Passant, see A-EP)
		 * B - Add into Source (Different in Promotion, see B-P)
		 * C - Remove Destination
		 * D - for Castling only
		 */
		public function undoMovePiece():void {
			var sqSrc:int = SRC(mvList[nMoveNum]);
			var sqDst:int = DST(mvList[nMoveNum]);
			var pc:int = pcSquares[sqDst];
			// __ASSERT((pcList[nMoveNum] & SIDE_TAG(sdPlayer)) == 0);
			// __ASSERT((pc & SIDE_TAG(sdPlayer)) != 0);
			addPiece(sqDst, pc, DEL_PIECE);
			addPiece(sqSrc, pc);
			if (pcList[nMoveNum] > 0) {
				addPiece(sqDst, pcList[nMoveNum]);
			}
			if (bSpecialMoveList[nMoveNum]) {
				if (PIECE_TYPE(pc) == PIECE_KING) {
					// CASTLING -> Move both King and Rook
					var nCastling:int = CASTLING_TYPE(sdPlayer, sqSrc, sqDst);
					// __ASSERT((castlingBits() & (1 << nCastling)) != 0);
					// __ASSERT(pcSquares[sqCastlingRookDst[nCastling]] == SIDE_TAG(sdPlayer) + PIECE_ROOK);
					// __ASSERT(pcSquares[sqCastlingRookSrc[nCastling]] == 0);
					addPiece(csqCastlingRookDst[nCastling], pc - PIECE_KING + PIECE_ROOK, DEL_PIECE); // D
					addPiece(csqCastlingRookSrc[nCastling], pc - PIECE_KING + PIECE_ROOK); // D
				} else if (PAWN_PROMOTION(sqDst, sdPlayer)) {
					// PROMOTION -> Add a Pawn instead of a Queen
					// __ASSERT(pc == SIDE_TAG(sdPlayer) + PIECE_QUEEN);
					addPiece(sqSrc, pc, DEL_PIECE); // B-P
					addPiece(sqSrc, pc - PIECE_QUEEN + PIECE_PAWN); // B-P
				} else {
					// __ASSERT(sqDst == enPassantSquare());
					// EN-PASSANT -> Adjust the Captured Pawn
					// __ASSERT(pcList[nMoveNum] == OPP_SIDE_TAG(sdPlayer) + PIECE_PAWN);
					addPiece(sqDst, pcList[nMoveNum], DEL_PIECE); // A-EP
					addPiece(sqDst - FORWARD_DELTA(sdPlayer), pcList[nMoveNum]); // A-EP
				}
			}
		}

		public function changeSide():void {
			sdPlayer = 1 - sdPlayer;
			dwKey ^= dwKeyPlayer;
			dwLock ^= dwLockPlayer;
		}

		public function makeMove(mv:int):Boolean {
			dwKeyList[nMoveNum] = dwKey;
			mvList[nMoveNum] = mv;
			movePiece();
			if (checked()) {
				undoMovePiece();
				return false;
			}
			changeSide();
			bCheckList[nMoveNum] = checked();
			nMoveNum ++;
			nDistance ++;
			return true;
		}

		public function undoMakeMove():void {
			nMoveNum --;
			nDistance --;
			changeSide();
			undoMovePiece();
		}

		public function nullMove():void {
			dwKeyList[nMoveNum] = dwKey;
			changeSide();
			mvList[nMoveNum] = pcList[nMoveNum] = sqEnPassantList[nMoveNum] = 0;
			bCheckList[nMoveNum] = bSpecialMoveList[nMoveNum] = false;
			nCastlingBitsList[nMoveNum] = castlingBits();
			nMoveNum ++;
			nDistance ++;
		}

		public function undoNullMove():void {
			nMoveNum --;
			nDistance --;
			changeSide();
		}

		public function generateMoves(mvs:Array, vls:Array = null):int {
			var nMoves:int = 0;
			var pcSelfSide:int = SIDE_TAG(sdPlayer);
			var pcOppSide:int = OPP_SIDE_TAG(sdPlayer);
			var i:int, j:int, nCastling:int, sqSrc:int, sqDst:int, sqTmp:int, pcSrc:int, pcDst:int, nDelta:int;
			// CASTLING -> Begin Generating Castling Moves
			if (vls == null) {
				for (i = 0; i < 2; i ++) {
					nCastling = (sdPlayer << 1) + i;
					if (canCastling(nCastling)) {
						mvs[nMoves] = MOVE(csqCastlingKingSrc[nCastling], csqCastlingKingDst[nCastling]);
						nMoves ++;
					}
				}
			}
			// CASTLING -> End Generating Castling Moves
			for (sqSrc = 0; sqSrc < 128; sqSrc ++) {
				pcSrc = pcSquares[sqSrc];
				if ((pcSrc & pcSelfSide) == 0) {
					continue;
				}
				switch (pcSrc - pcSelfSide) {
				case PIECE_KING:
					for (i = 0; i < 8; i ++) {
						sqDst = sqSrc + cnKingDelta[i];
						if (!IN_BOARD(sqDst)) {
							continue;
						}
						pcDst = pcSquares[sqDst];
						if (vls == null) {
							if ((pcDst & pcSelfSide) == 0) {
								mvs[nMoves] = MOVE(sqSrc, sqDst);
								nMoves ++;
							}
						} else if ((pcDst & pcOppSide) != 0) {
							mvs[nMoves] = MOVE(sqSrc, sqDst);
							vls[nMoves] = MVV_LVA(pcDst, 99);
							nMoves ++;
						}
					}
					break;
				case PIECE_QUEEN:
					for (i = 0; i < 8; i ++) {
						nDelta = cnKingDelta[i];
						sqDst = sqSrc + nDelta;
						while (IN_BOARD(sqDst)) {
							pcDst = pcSquares[sqDst];
							if (pcDst == 0) {
								if (vls == null) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									nMoves ++;
								}
							} else {
								if ((pcDst & pcOppSide) != 0) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									if (vls != null) {
										vls[nMoves] = MVV_LVA(pcDst, 9);
									}
									nMoves ++;
								}
								break;
							}
							sqDst += nDelta;
						}
					}
					break;
				case PIECE_ROOK:
					for (i = 0; i < 4; i ++) {
						nDelta = cnRookDelta[i];
						sqDst = sqSrc + nDelta;
						while (IN_BOARD(sqDst)) {
							pcDst = pcSquares[sqDst];
							if (pcDst == 0) {
								if (vls == null) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									nMoves ++;
								}
							} else {
								if ((pcDst & pcOppSide) != 0) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									if (vls != null) {
										vls[nMoves] = MVV_LVA(pcDst, 5);
									}
									nMoves ++;
								}
								break;
							}
							sqDst += nDelta;
						}
					}
					break;
				case PIECE_BISHOP:
					for (i = 0; i < 4; i ++) {
						nDelta = cnBishopDelta[i];
						sqDst = sqSrc + nDelta;
						while (IN_BOARD(sqDst)) {
							pcDst = pcSquares[sqDst];
							if (pcDst == 0) {
								if (vls == null) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									nMoves ++;
								}
							} else {
								if ((pcDst & pcOppSide) != 0) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									if (vls != null) {
										vls[nMoves] = MVV_LVA(pcDst, 3);
									}
									nMoves ++;
								}
								break;
							}
							sqDst += nDelta;
						}
					}
					break;
				case PIECE_KNIGHT:
					for (i = 0; i < 8; i ++) {
						sqDst = sqSrc + cnKnightDelta[i];
						if (!IN_BOARD(sqDst)) {
							continue;
						}
						pcDst = pcSquares[sqDst];
						if (vls == null) {
							if ((pcDst & pcSelfSide) == 0) {
								mvs[nMoves] = MOVE(sqSrc, sqDst);
								nMoves ++;
							}
						} else if ((pcDst & pcOppSide) != 0) {
							mvs[nMoves] = MOVE(sqSrc, sqDst);
							vls[nMoves] = MVV_LVA(pcDst, 3);
							nMoves ++;
						}
					}
					break;
				case PIECE_PAWN:
					nDelta = FORWARD_DELTA(sdPlayer);
					sqDst = sqSrc + nDelta;
					if (vls == null) {
						if (IN_BOARD(sqDst) && pcSquares[sqDst] == 0) {
							mvs[nMoves] = MOVE(sqSrc, sqDst);
							nMoves ++;
							if (PAWN_INIT(sqSrc, sdPlayer)) {
								sqDst += nDelta;
								if (pcSquares[sqDst] == 0) {
									mvs[nMoves] = MOVE(sqSrc, sqDst);
									nMoves ++;
								}
							}
						}
					} else {
						// PROMOTION -> Promotions are regarded as Capture Moves
						if (PAWN_PROMOTION(sqDst, sdPlayer) && pcSquares[sqDst] == 0) {
							mvs[nMoves] = MOVE(sqSrc, sqDst);
							vls[nMoves] = MVV_LVA(PIECE_QUEEN, 1);
							nMoves ++;
						}
					}
					sqTmp = sqSrc + nDelta;
					for (i = -1; i <= 1; i += 2) {
						sqDst = sqTmp + i;
						if (!IN_BOARD(sqDst)) {
							continue;
						}
						pcDst = pcSquares[sqDst];
						// EN-PASSANT -> En-passant considered
						if (sqDst == enPassantSquare()) {
							pcDst = pcSquares[sqDst - nDelta];
						}
						if ((pcDst & pcOppSide) != 0) {
							mvs[nMoves] = MOVE(sqSrc, sqDst);
							if (vls != null) {
								vls[nMoves] = MVV_LVA(pcDst, 1);
							}
							nMoves ++;
						}
					}
					break;
				}
			}
			return nMoves;
		}

		public function legalMove(mv:int):Boolean {
			var sqSrc:int = SRC(mv);
			var pcSrc:int = pcSquares[sqSrc];
			var pcSelfSide:int = SIDE_TAG(sdPlayer);
			if ((pcSrc & pcSelfSide) == 0) {
				return false;
			}

			var sqDst:int = DST(mv);
			var pcDst:int = pcSquares[sqDst];
			if ((pcDst & pcSelfSide) != 0) {
				return false;
			}

			var sqTmp:int, nDelta:int;
			var nPieceType = pcSrc - pcSelfSide;
			switch (nPieceType) {
			case PIECE_KING:
				if (KING_SPAN(sqSrc, sqDst)) {
					return true;
				}
				// CASTLING -> Castling considered
				var nCastling:int = CASTLING_TYPE(sdPlayer, sqSrc, sqDst);
				return (csqCastlingKingDst[nCastling] == sqDst && canCastling(nCastling));
			case PIECE_KNIGHT:
				return KNIGHT_SPAN(sqSrc, sqDst);
			case PIECE_QUEEN:
			case PIECE_ROOK:
			case PIECE_BISHOP:
				switch (SAME_LINE(sqSrc, sqDst)) {
				case DIFF_LINE:
					return false;
				case SAME_RANK:
					if (nPieceType == PIECE_BISHOP) {
						return false;
					}
					nDelta = (sqDst < sqSrc ? -1 : 1);
					break;
				case SAME_FILE:
					if (nPieceType == PIECE_BISHOP) {
						return false;
					}
					nDelta = (sqDst < sqSrc ? -16 : 16);
					break;
				case SAME_DIAG_A1H8:
					if (nPieceType == PIECE_ROOK) {
						return false;
					}
					nDelta = (sqDst < sqSrc ? -15 : 15);
					break;
				case SAME_DIAG_A8H1:
					if (nPieceType == PIECE_ROOK) {
						return false;
					}
					nDelta = (sqDst < sqSrc ? -17 : 17);
					break;
				default: // Never Occurs
					// __ASSERT(false);
				}
				sqTmp = sqSrc + nDelta;
				while (sqTmp != sqDst) {
					if (pcSquares[sqTmp] > 0) {
						return false;
					}
					sqTmp += nDelta;
				}
				return true;
			case PIECE_PAWN:
				nDelta = FORWARD_DELTA(sdPlayer);
				sqTmp = sqSrc + nDelta;
				// EN-PASSANT -> En-passant is a capture move but "pcDst != 0"
				if (pcDst != 0 || sqDst == enPassantSquare()) {
					return (sqDst == sqTmp - 1 || sqDst == sqTmp + 1);
				}
				return (sqDst == sqTmp || (sqDst == sqTmp + nDelta &&
						PAWN_INIT(sqSrc, sdPlayer) && pcSquares[sqTmp] == 0));
			default:
				return false;
			}
		}

		public function squareChecked(sqSrc:int):Boolean {
			var pcOppSide:int = OPP_SIDE_TAG(sdPlayer);
			var sqTmp:int = sqSrc + FORWARD_DELTA(sdPlayer);
			var i:int, sqDst:int, pcDst:int, nDelta:int;
			for (i = -1; i <= 1; i += 2) {
				sqDst = sqTmp + i;
				if (IN_BOARD(sqDst) && pcSquares[sqDst] == pcOppSide + PIECE_PAWN) {
					return true;
				}
			}
			for (i = 0; i < 8; i ++) {
				sqDst = sqSrc + cnKingDelta[i];
				if (IN_BOARD(sqDst) && pcSquares[sqDst] == pcOppSide + PIECE_KING) {
					return true;
				}
			}
			for (i = 0; i < 8; i ++) {
				sqDst = sqSrc + cnKnightDelta[i];
				if (IN_BOARD(sqDst) && pcSquares[sqDst] == pcOppSide + PIECE_KNIGHT) {
					return true;
				}
			}
			for (i = 0; i < 4; i ++) {
				nDelta = cnBishopDelta[i];
				sqDst = sqSrc + nDelta;
				while (IN_BOARD(sqDst)) {
					pcDst = pcSquares[sqDst];
					if (pcDst > 0) {
						if (pcDst == pcOppSide + PIECE_BISHOP || pcDst == pcOppSide + PIECE_QUEEN) {
							return true;
						}
						break;
					}
					sqDst += nDelta;
				}
			}
			for (i = 0; i < 4; i ++) {
				nDelta = cnRookDelta[i];
				sqDst = sqSrc + nDelta;
				while (IN_BOARD(sqDst)) {
					pcDst = pcSquares[sqDst];
					if (pcDst > 0) {
						if (pcDst == pcOppSide + PIECE_ROOK || pcDst == pcOppSide + PIECE_QUEEN) {
							return true;
						}
						break;
					}
					sqDst += nDelta;
				}
			}
			return false;
		}

		public function checked():Boolean {
			var pcSelfSide:int = SIDE_TAG(sdPlayer);
			var sqSrc:int;
			for (sqSrc = 0; sqSrc < 128; sqSrc ++) {
				if (pcSquares[sqSrc] == pcSelfSide + PIECE_KING) {
					return squareChecked(sqSrc);
				}
			}
			return false;
		}

		public function isMate():Boolean {
			var mvs:Array = new Array(MAX_GEN_MOVES);
			var nMoves:int = generateMoves(mvs);
			var i:int;
			for (i = 0; i < nMoves; i ++) {
				if (makeMove(mvs[i])) {
					undoMakeMove();
					return false;
				}
			}
			return true;
		}

		public function drawValue():int {
			return (nDistance & 1) == 0 ? -DRAW_VALUE : DRAW_VALUE;
		}

		public function mateValue():int {
			return inCheck() ? nDistance - MATE_VALUE : drawValue();
		}

		public function material():int {
			return (sdPlayer == 0 ? vlWhite - vlBlack : vlBlack - vlWhite) + ADVANCED_VALUE;
		}

		public function nullOkay():Boolean {
			return (sdPlayer == 0 ? vlWhite : vlBlack) > NULL_OKAY_MARGIN;
		}

		public function nullSafe():Boolean {
			return (sdPlayer == 0 ? vlWhite : vlBlack) > NULL_SAFE_MARGIN;
		}

		public function isRep(nRecur:int = 1):Boolean {
			var bSelfSide:Boolean = false;
			var nIndex:int = nMoveNum - 1;
			while (mvList[nIndex] > 0 && pcList[nIndex] == 0) {
				if (bSelfSide) {
					if (dwKeyList[nIndex] == dwKey) {
						nRecur --;
						if (nRecur == 0) {
							return true;
						}
					}
				}
				bSelfSide = !bSelfSide;
				nIndex --;
			}
			return false;
		}

		private function fenPiece(c:String):int {
			switch (c) {
			case 'K':
				return PIECE_KING;
			case 'Q':
				return PIECE_QUEEN;
			case 'R':
				return PIECE_ROOK;
			case 'B':
				return PIECE_BISHOP;
			case 'N':
				return PIECE_KNIGHT;
			case 'P':
				return PIECE_PAWN;
			default:
				return -1;
			}
		}

		public static function PARSE_COORD(str:String, index:int):int {
			var sq:int = 0;
			if (index == str.length) {
				return 0;
			}
			var c:String = str.charAt(index);
			if (c >= 'a' && c <= 'h') {
				if (index + 1 == str.length) {
					return 0;
				}
				var c2:String = str.charAt(index + 1);
				if (c2 >= '1' && c2 <= '8') {
					sq = COORD_XY(c.charCodeAt() - 'a'.charCodeAt() + FILE_LEFT, '8'.charCodeAt() - c2.charCodeAt() + RANK_TOP);
				}
			}
			return sq;
		}

		public function fromFen(fen:String):void {
			clearBoard();
			var y:int = RANK_TOP;
			var x:int = FILE_LEFT;
			var index:int = 0;
			if (index == fen.length) {
				setIrrevEx(0, 0);
				return;
			}
			var pt:int;
			var c:String = fen.charAt(index);
			while (c != ' ') {
				if (c == '/') {
					x = FILE_LEFT;
					y ++;
					if (y > RANK_BOTTOM) {
						break;
					}
				} else if (c >= '1' && c <= '9') {
					var kk:int = c.charCodeAt() - '0'.charCodeAt();
					for (var k:int = 0; k < kk; k ++) {
						if (x >= FILE_RIGHT) {
							break;
						}
						x ++;
					}
				} else if (c >= 'A' && c <= 'Z') {
					if (x <= FILE_RIGHT) {
						if (c != 'P' || (y != RANK_TOP && y != RANK_BOTTOM)) {
							pt = fenPiece(c);
							if (pt >= 0) {
								addPiece(COORD_XY(x, y), pt + 8);
							}
						}
						x ++;
					}
				} else if (c >= 'a' && c <= 'z') {
					if (x <= FILE_RIGHT) {
						if (c != 'p' || (y != RANK_TOP && y != RANK_BOTTOM)) {
							pt = fenPiece(String.fromCharCode(c.charCodeAt() + 'A'.charCodeAt() - 'a'.charCodeAt()));
							if (pt >= 0) {
								addPiece(COORD_XY(x, y), pt + 16);
							}
						}
						x ++;
					}
				}
				index ++;
				if (index == fen.length) {
					setIrrevEx(0, 0);
					return;
				}
				c = fen.charAt(index);
			}
			index ++;
			if (index == fen.length) {
				setIrrevEx(0, 0);
				return;
			}
			if (sdPlayer == (fen.charAt(index) == 'b' ? 0 : 1)) {
				changeSide();
			}
			index ++; // Skip a ' '
			if (index == fen.length) {
				setIrrevEx(0, 0);
				return;
			}
			var nCastlingBits:int = 0;
			index ++;
			if (index == fen.length) {
				setIrrevEx(0, 0);
				return;
			}
			c = fen.charAt(index);
			while (c != ' ') {
				switch (c) {
				case 'K':
					if (pcSquares[0x78] == 8 && pcSquares[0x7b] == 10) {
						nCastlingBits += 1;
					}
					break;
				case 'Q':
					if (pcSquares[0x78] == 8 && pcSquares[0x74] == 10) {
						nCastlingBits += 2;
					}
					break;
				case 'k':
					if (pcSquares[0x08] == 16 && pcSquares[0x0b] == 18) {
						nCastlingBits += 4;
					}
					break;
				case 'q':
					if (pcSquares[0x08] == 16 && pcSquares[0x04] == 18) {
						nCastlingBits += 8;
					}
					break;
				}
				index ++;
				if (index == fen.length) {
					setIrrevEx(nCastlingBits, 0);
					return;
				}
				c = fen.charAt(index);
			}
			var sqEnPassant:int = PARSE_COORD(fen, index + 1);
			if (sqEnPassant > 0 && PAWN_EN_PASSANT(sqEnPassant, sdPlayer) &&
					pcSquares[sqEnPassant - FORWARD_DELTA(sdPlayer)] > 0) {
				setIrrevEx(nCastlingBits, sqEnPassant);
			} else {
				setIrrevEx(nCastlingBits, 0);
			}
		}

		public function bookMove():int {
			if (nBookSize == 0) {
				return 0;
			}
			var nIndex = Util.binarySearch(dwLock, dwBookLock, 0, nBookSize);
			if (nIndex < 0) {
				return 0;
			}
			nIndex --;
			while (nIndex >= 0 && dwBookLock[nIndex] == dwLock) {
				nIndex --;
			}
			var mvs:Array = new Array(MAX_GEN_MOVES);
			var vls:Array = new Array(MAX_GEN_MOVES);
			var vl:int = 0;
			var nMoves:int = 0;
			nIndex ++;
			while (nIndex < nBookSize && dwBookLock[nIndex] == dwLock) {
				var mv:int = mvBook[nIndex];
				if (legalMove(mv)) {
					mvs[nMoves] = mv;
					vls[nMoves] = vlBook[nIndex];
					vl += vls[nMoves];
					nMoves ++;
					if (nMoves == MAX_GEN_MOVES) {
						break;
					}
				}
				nIndex ++;
			}
			if (vl == 0) {
				return 0;
			}
			vl = int(Math.random() * vl);
			for (nIndex = 0; nIndex < nMoves; nIndex ++) {
				vl -= vls[nIndex];
				if (vl < 0) {
					break;
				}
			}
			return mvs[nIndex];
		}

		public function historyIndex(mv:int):int {
			return ((pcSquares[SRC(mv)] - 8) << 7) + DST(mv);
		}

		private static var PIECE_STRING:String = "KQRBNP";

		public function traceBoard():void {
			var s:String;
			var x:int, y:int, pc:int;
			for (y = Position.RANK_TOP; y <= Position.RANK_BOTTOM; y ++) {
				s = String.fromCharCode('8'.charCodeAt() - y) + "|";
				for (x = Position.FILE_LEFT; x <= Position.FILE_RIGHT; x ++) {
					pc = pcSquares[Position.COORD_XY(x, y)];
					if (pc > 0) {
						if (pc < 16) {
							s += PIECE_STRING.charAt(pc - 8);
						} else {
							s += String.fromCharCode(PIECE_STRING.charAt(pc - 16).charCodeAt() -
									'A'.charCodeAt() + 'a'.charCodeAt());
						}
					} else {
						s += ".";
					}
					s += " ";
				}
				trace(s);
			}
			trace(" +----------------");
			trace("  a b c d e f g h");
		}
	}
}
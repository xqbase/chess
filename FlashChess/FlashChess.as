/*
FlashChess.as - Source Code for Flash Chess, Part III

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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.Sound;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class FlashChess extends Sprite {
		private static const STARTUP_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

		private static const PHASE_LOADING:int = 0;
		private static const PHASE_WAITING:int = 1;
		private static const PHASE_THINKING:int = 2;

		private static const COMPUTER_BLACK:int = 0;
		private static const COMPUTER_WHITE:int = 1;
		private static const COMPUTER_NONE:int = 2;

		private static const RESP_CLICK:int = 0;
		private static const RESP_ILLEGAL:int = 1;
		private static const RESP_MOVE:int = 2;
		private static const RESP_MOVE2:int = 3;
		private static const RESP_CAPTURE:int = 4;
		private static const RESP_CAPTURE2:int = 5;
		private static const RESP_SPECIAL:int = 6;
		private static const RESP_SPECIAL2:int = 7;
		private static const RESP_CHECK:int = 8;
		private static const RESP_CHECK2:int = 9;
		private static const RESP_WIN:int = 10;
		private static const RESP_DRAW:int = 11;
		private static const RESP_LOSS:int = 12;

		private static const BOARD_EDGE:int = 4;
		private static const SQUARE_SIZE:int = 41;
		private static const BITMAP_SIZE:int = 41;
		private static const THINKING_SIZE:int = 48;
		private static const BOARD_SIZE:int = BOARD_EDGE + SQUARE_SIZE * 8 + BOARD_EDGE;

		private static const bmpOo:BitmapData = new EmptySquare(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWk:BitmapData = new WhiteKing(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWq:BitmapData = new WhiteQueen(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWr:BitmapData = new WhiteRook(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWb:BitmapData = new WhiteBishop(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWn:BitmapData = new WhiteKnight(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWp:BitmapData = new WhitePawn(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBk:BitmapData = new BlackKing(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBq:BitmapData = new BlackQueen(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBr:BitmapData = new BlackRook(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBb:BitmapData = new BlackBishop(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBn:BitmapData = new BlackKnight(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBp:BitmapData = new BlackPawn(BITMAP_SIZE, BITMAP_SIZE);

		private static const bmpOos:BitmapData = new EmptySquareSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWks:BitmapData = new WhiteKingSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWqs:BitmapData = new WhiteQueenSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWrs:BitmapData = new WhiteRookSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWbs:BitmapData = new WhiteBishopSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWns:BitmapData = new WhiteKnightSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpWps:BitmapData = new WhitePawnSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBks:BitmapData = new BlackKingSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBqs:BitmapData = new BlackQueenSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBrs:BitmapData = new BlackRookSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBbs:BitmapData = new BlackBishopSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBns:BitmapData = new BlackKnightSelected(BITMAP_SIZE, BITMAP_SIZE);
		private static const bmpBps:BitmapData = new BlackPawnSelected(BITMAP_SIZE, BITMAP_SIZE);


		private static const sndClick:Sound = new ClickSound();
		private static const sndIllegal:Sound = new IllegalSound();
		private static const sndMove:Sound = new MoveSound();
		private static const sndMove2:Sound = new Move2Sound();
		private static const sndCapture:Sound = new CaptureSound();
		private static const sndCapture2:Sound = new Capture2Sound();
		private static const sndSpecial:Sound = new SpecialSound();
		private static const sndSpecial2:Sound = new Special2Sound();
		private static const sndCheck:Sound = new CheckSound();
		private static const sndCheck2:Sound = new Check2Sound();
		private static const sndWin:Sound = new WinSound();
		private static const sndDraw:Sound = new DrawSound();
		private static const sndLoss:Sound = new LossSound();

		private static const bmpPieces:Array = new Array(
			bmpOo, null, null, null, null, null, null, null,
			bmpWk, bmpWq, bmpWr, bmpWb, bmpWn, bmpWp, null, null,
			bmpBk, bmpBq, bmpBr, bmpBb, bmpBn, bmpBp, null, null
		);

		private static const bmpSelected:Array = new Array(
			bmpOos, null, null, null, null, null, null, null,
			bmpWks, bmpWqs, bmpWrs, bmpWbs, bmpWns, bmpWps, null, null,
			bmpBks, bmpBqs, bmpBrs, bmpBbs, bmpBns, bmpBps, null, null
		);

		private static const sndResponse:Array = new Array(
			sndClick, sndIllegal, sndMove, sndMove2, sndCapture, sndCapture2,
			sndSpecial, sndSpecial2, sndCheck, sndCheck2, sndWin, sndDraw, sndLoss
		);

		private var bmpThinking:Bitmap = new Bitmap();
		private var bmpSquares:Array = new Array(256);
		private var pos:Position = new Position();
		private var search:Search = new Search(pos, 16);
		private var bSound:Boolean = true;
		private var nMoveMode = 0, nLevel:int = 0;
		private var sqSelected:int = 0, mvLast:int = 0;
		private var sdCurrent:int = 0, sdRetract:int = 0;
		private var nCastlingCurrent:int = 0, nCastlingRetract:int = 0;
		private var sqEpCurrent:int = 0, sqEpRetract:int = 0;
		private var pcCurrent:Array = new Array(256), pcRetract:Array = new Array(256);
		private var nPhase:int = PHASE_LOADING;

		private static const DRAW_SELECTED:Boolean = true;

		private function drawSquare(sq:int, bSelected:Boolean = false):void {
			var pc:int = pos.pcSquares[sq];
			sq = nMoveMode == COMPUTER_WHITE ? Position.SQUARE_FLIP(sq) : sq;
			bmpSquares[sq].bitmapData = bSelected ? bmpSelected[pc] : bmpPieces[pc];
		}

		private function drawMove(mv:int, bSelected:Boolean = false):void {
			drawSquare(Position.SRC(mvLast), bSelected);
			drawSquare(Position.DST(mvLast), bSelected);
		}

		private function playSound(nResponse:int):void {
			if (bSound) {
				Sound(sndResponse[nResponse]).play();
			}
		}

		private function setMessage(s:String):void {
			lblMessage.htmlText = "<b><i>" + s + "</b></i>";
			lblMessage.visible = true;
		}

		private function saveCurrent():void {
			sdCurrent = pos.sdPlayer;
			nCastlingCurrent = pos.castlingBits();
			sqEpCurrent = pos.enPassantSquare();
			var sq:int;
			for (sq = 0; sq < 256; sq ++) {
				pcCurrent[sq] = pos.pcSquares[sq];
			}
		}

		private function saveRetract():void {
			sdRetract = sdCurrent;
			nCastlingRetract = nCastlingCurrent;
			sqEpRetract = sqEpCurrent;
			var sq:int;
			for (sq = 0; sq < 256; sq ++) {
				pcRetract[sq] = pcCurrent[sq];
			}
			saveCurrent();
		}

		private function getResult(nResponse:int = -1):Boolean {
			if (pos.isMate()) {
				if (pos.inCheck()) {
					playSound(nResponse < 0 ? RESP_WIN : RESP_LOSS);
					setMessage(nResponse < 0 ? "You Win!" : "You Lose!");
				} else {
					playSound(RESP_DRAW);
					setMessage("Draw by Stalemate!");
				}
				return true;
			}
			if (pos.isRep(2)) {
				playSound(RESP_DRAW);
				setMessage("Draw by Repetition!");
				return true;
			}
			if (pos.nMoveNum > 100) {
				playSound(RESP_DRAW);
				setMessage("Draw by 50-Move Rule!");
				return true;
			}
			if (nResponse >= 0) {
				playSound(nResponse);
				saveRetract();
			}
			return false;
		}

		private function addMove(mv:int):Boolean {
			if (pos.legalMove(mv)) {
				var sqSrc:int = Position.SRC(mv);
				var sqDst:int = Position.DST(mv);
				var pc:int = pos.pcSquares[sqSrc];
				if (pos.makeMove(mv)) {
					mvLast = mv;
					drawMove(mvLast, DRAW_SELECTED);
					if (pos.specialMove()) {
						if (Position.PIECE_TYPE(pc) == Position.PIECE_KING) {
							var nCastling:int = Position.CASTLING_TYPE(1 - pos.sdPlayer, sqSrc, sqDst);
							drawSquare(Position.csqCastlingRookSrc[nCastling]);
							drawSquare(Position.csqCastlingRookDst[nCastling]);
						} else {
							drawSquare(sqDst - Position.FORWARD_DELTA(1 - pos.sdPlayer));
						}
					}
					sqSelected = 0;
					playSound(pos.inCheck() ? RESP_CHECK : pos.specialMove() ?
							RESP_SPECIAL : pos.captured() ? RESP_CAPTURE : RESP_MOVE);
					if (pos.captured() || Position.PIECE_TYPE(pc) == Position.PIECE_PAWN) {
						pos.setIrrev();
					}
					return true;
				} else {
					playSound(RESP_ILLEGAL);
				}
			}
			return false;
		}

		private function responseMove(e:TimerEvent):void {
			var mv:int = search.searchMain(1000 << (nLevel << 1));
			if (mvLast > 0) {
				drawMove(mvLast);
			}
			mvLast = mv;
			var sqSrc:int = Position.SRC(mvLast);
			var sqDst:int = Position.DST(mvLast);
			var pc:int = pos.pcSquares[sqSrc];
			pos.makeMove(mvLast);
			drawMove(mvLast, DRAW_SELECTED);
			if (pos.specialMove()) {
				if (Position.PIECE_TYPE(pc) == Position.PIECE_KING) {
					var nCastling:int = Position.CASTLING_TYPE(1 - pos.sdPlayer, sqSrc, sqDst);
					drawSquare(Position.csqCastlingRookSrc[nCastling]);
					drawSquare(Position.csqCastlingRookDst[nCastling]);
				} else {
					drawSquare(sqDst - Position.FORWARD_DELTA(1 - pos.sdPlayer));
				}
			}
			var nResponse:int = pos.inCheck() ? RESP_CHECK2 : pos.specialMove() ?
					RESP_SPECIAL2 : pos.captured() ? RESP_CAPTURE2 : RESP_MOVE2;
			if (pos.captured() || Position.PIECE_TYPE(pc) == Position.PIECE_PAWN) {
				pos.setIrrev();
			}
			bmpThinking.visible = false;
			nPhase = getResult(nResponse) ? PHASE_LOADING : PHASE_WAITING;
		}

		private function thinking():void {
			nPhase = PHASE_THINKING;
			var sq:int = Position.DST(mvLast);
			bmpThinking.visible = true;
			var timer:Timer = new Timer(100, 1);
			timer.addEventListener(TimerEvent.TIMER, responseMove);
			timer.start();
		}

		private function clickSquare(sq:int):void {
			sq = nMoveMode == COMPUTER_WHITE ? Position.SQUARE_FLIP(sq) : sq;
			var pc:int = pos.pcSquares[sq];
			if ((pc & Position.SIDE_TAG(pos.sdPlayer)) != 0) {
				if (sqSelected != 0) {
					drawSquare(sqSelected);
				}
				sqSelected = sq;
				drawSquare(sq, DRAW_SELECTED);
				if (mvLast != 0) {
					drawMove(mvLast);
				}
				playSound(RESP_CLICK);
			} else if (sqSelected != 0) {
				var mv:int = Position.MOVE(sqSelected, sq);
				if (addMove(mv)) {
					if (getResult()) {
						nPhase = PHASE_LOADING;
					} else if (nMoveMode == COMPUTER_NONE) {
						saveRetract();
					} else {
						thinking();
					}
				}
			}
		}

		private function onClick(e:MouseEvent):void {
			if (Position.nBookSize >= 0 && nPhase == PHASE_WAITING) {
				var xx:int = Position.FILE_LEFT + (e.localX - BOARD_EDGE) / SQUARE_SIZE;
				var yy:int = Position.RANK_TOP + (e.localY - BOARD_EDGE) / SQUARE_SIZE;
				if (xx >= Position.FILE_LEFT && xx <= Position.FILE_RIGHT &&
						yy >= Position.RANK_TOP && yy <= Position.RANK_BOTTOM) {
					clickSquare(Position.COORD_XY(xx, yy));
				}
			}
		}

		private function drawBoard():void {
			var sq:int;
			for (sq = 0; sq < 256; sq ++) {
				if (Position.IN_BOARD(sq)) {
					drawSquare(sq);
				}
			}
		}

		private function restart(nMoveMode_:int, fen:String):void {
			if (nPhase == PHASE_THINKING) {
				return;
			}
			nPhase = PHASE_LOADING;
			nMoveMode = nMoveMode_;
			pos.fromFen(fen);
			sdCurrent = pos.sdPlayer;
			saveCurrent();
			saveRetract();
			sqSelected = mvLast = 0;
			drawBoard();
			lblMessage.visible = false;
			if (sdCurrent == 0 ? nMoveMode == COMPUTER_WHITE : nMoveMode == COMPUTER_BLACK) {
				thinking();
			} else {
				nPhase = PHASE_WAITING;
			}
		}

		private function retract():void {
			lblMessage.visible = false;
			pos.clearBoard();
			var sq:int;
			for (sq = 0; sq < 256; sq ++) {
				if (pcRetract[sq] > 0) {
					pos.addPiece(sq, pcRetract[sq]);
				}
			}
			if (sdRetract == 1) {
				pos.changeSide();
			}
			pos.setIrrevEx(nCastlingRetract, sqEpRetract);
			saveCurrent();
			sqSelected = mvLast = 0;
			drawBoard();
			if (sdCurrent == 0 ? nMoveMode == COMPUTER_WHITE : nMoveMode == COMPUTER_BLACK) {
				thinking();
			} else {
				nPhase = PHASE_WAITING;
			}
		}

		private function setLevel(nLevel_:int):void {
			nLevel = nLevel_;
		}

		private function setSound(bSound_:Boolean):void {
			bSound = bSound_;
			playSound(RESP_CLICK);
		}

		public function FlashChess() {
			var board:Sprite = new Sprite();
			var sq:int;
			for (sq = 0; sq < 256; sq ++) {
				if (Position.IN_BOARD(sq)) {
					bmpSquares[sq] = new Bitmap();
					bmpSquares[sq].x = BOARD_EDGE + (Position.FILE_X(sq) - Position.FILE_LEFT) * SQUARE_SIZE;
					bmpSquares[sq].y = BOARD_EDGE + (Position.RANK_Y(sq) - Position.RANK_TOP) * SQUARE_SIZE;
					board.addChild(bmpSquares[sq]);
				}
			}
			board.addEventListener(MouseEvent.MOUSE_DOWN, onClick);
			bmpThinking.bitmapData = new ThinkingImage(THINKING_SIZE, THINKING_SIZE);
			bmpThinking.x = bmpThinking.y = (BOARD_SIZE - THINKING_SIZE) / 2;
			bmpThinking.visible = false;
			board.addChild(bmpThinking);
			addChild(board);
			setChildIndex(lblMessage, numChildren - 1);
			var nMode:int = loaderInfo.parameters.mode;
			var szFen:String = loaderInfo.parameters.fen;
			if (szFen == null) {
				szFen = STARTUP_FEN;
			}
			restart(nMode, szFen);
			ExternalInterface.addCallback("restart", restart);
			ExternalInterface.addCallback("retract", retract);
			ExternalInterface.addCallback("setLevel", setLevel);
			ExternalInterface.addCallback("setSound", setSound);
		}
	}
}
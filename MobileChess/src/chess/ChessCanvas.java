/*
ChessCanvas.java - Source Code for Mobile Chess, Part IV

Mobile Chess - a Chess Program for Java ME
Designed by Morning Yellow, Version: 1.20, Last Modified: Mar. 2013
Copyright (C) 2008-2013 www.chess-wizard.com

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
package chess;

import javax.microedition.lcdui.Alert;
import javax.microedition.lcdui.AlertType;
import javax.microedition.lcdui.Canvas;
import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Font;
import javax.microedition.lcdui.Graphics;
import javax.microedition.lcdui.Image;

class ChessCanvas extends Canvas {
	private static final int PHASE_LOADING = 0;
	private static final int PHASE_WAITING = 1;
	private static final int PHASE_THINKING = 2;
	private static final int PHASE_EXITTING = 3;

	private static final int COMPUTER_BLACK = 0;
	private static final int COMPUTER_WHITE = 1;
	private static final int COMPUTER_NONE = 2;

	private static final int RESP_HUMAN_SINGLE = -2;
	private static final int RESP_HUMAN_BOTH = -1;
	private static final int RESP_CLICK = 0;
	private static final int RESP_ILLEGAL = 1;
	private static final int RESP_MOVE = 2;
	private static final int RESP_MOVE2 = 3;
	private static final int RESP_CAPTURE = 4;
	private static final int RESP_CAPTURE2 = 5;
	private static final int RESP_SPECIAL = 6;
	private static final int RESP_SPECIAL2 = 7;
	private static final int RESP_CHECK = 8;
	private static final int RESP_CHECK2 = 9;
	private static final int RESP_WIN = 10;
	private static final int RESP_DRAW = 11;
	private static final int RESP_LOSS = 12;

	private static Image imgBackground, imgChess, imgThinking;
	private static final String[] IMAGE_NAME = {
		null, null, null, null, null, null, null, null,
		"wk", "wq", "wr", "wb", "wn", "wp", null, null,
		"bk", "bq", "br", "bb", "bn", "bp", null, null,
	};
	private static int widthBackground, heightBackground;
	private static Font fontLarge = Font.getFont(Font.FACE_SYSTEM,
			Font.STYLE_BOLD + Font.STYLE_ITALIC, Font.SIZE_LARGE);
	private static Font fontSmall = Font.getFont(Font.FACE_SYSTEM,
			Font.STYLE_BOLD, Font.SIZE_SMALL);

	static {
		try {
			imgBackground = Image.createImage("/images/background.png");
			imgChess = Image.createImage("/images/chess.png");
			imgThinking = Image.createImage("/images/thinking.png");
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage());
		}
		widthBackground = imgBackground.getWidth();
		heightBackground = imgBackground.getHeight();
	}

	ChessMIDlet midlet;
	byte[] retractData = new byte[ChessMIDlet.RS_DATA_LEN];

	private Position pos = new Position();
	private Search search = new Search(pos, 12);
	private String message;
	private int cursorX, cursorY;
	private int sqSelected, mvLast;
	// Assume FullScreenMode = false
	private int normalWidth = getWidth();
	private int normalHeight = getHeight();

	private Alert altAbout = new Alert("About \"Mobile Chess\"", null, imgChess, AlertType.INFO);
	private Alert altBack = new Alert("Mobile Chess", "Abort Current Game?", null, AlertType.CONFIRMATION);

	Command cmdBack = new Command("Back", Command.ITEM, 1);
	Command cmdRetract = new Command("Retract", Command.ITEM, 1);
	Command cmdAbout = new Command("About", Command.ITEM, 1);
	Command cmdBackOK = new Command("OK", Command.OK, 1);
	Command cmdBackCancel = new Command("Cancel", Command.CANCEL, 1);

	volatile int phase = PHASE_LOADING;

	private boolean init = false;
	private Image imgBoard, imgSelected, imgCursor;
	private Image[] imgPieces = new Image[24];
	private int squareSize, width, height;
	private int left, right, top, bottom;

	ChessCanvas(ChessMIDlet midlet_) {
		this.midlet = midlet_;
		setFullScreenMode(true);
		altAbout.setTimeout(Alert.FOREVER);
		altAbout.setString(midlet.getAppProperty("MIDlet-Description") + " " +
				midlet.getAppProperty("MIDlet-Version") + "\n\r\f\n\r\f" +
				"(C) 2008-2013 www.chess-wizard.com\n\r\f" +
				"(C) 2010-2013 Shanghai Xianqu Info-Tech Co., Ltd.");
		altBack.setTimeout(Alert.FOREVER);
		altBack.addCommand(cmdBackOK);
		altBack.addCommand(cmdBackCancel);
		altBack.setCommandListener(new CommandListener() {
			public void commandAction(Command c, Displayable d) {
				if (c == cmdBackOK) {
					midlet.rsData[0] = 0;
					midlet.startMusic("form");
					Display.getDisplay(midlet).setCurrent(midlet.form);
				} else {
					Display.getDisplay(midlet).setCurrent(ChessCanvas.this);
					phase = PHASE_LOADING;
					setFullScreenMode(true);
				}
			}
		});
		addCommand(cmdBack);
		addCommand(cmdRetract);
		addCommand(cmdAbout);

		setCommandListener(new CommandListener() {
			public void commandAction(Command c, Displayable d) {
				if (phase == PHASE_WAITING || phase == PHASE_EXITTING) {
					if (c == cmdBack) {
						back();
					} else if (c == cmdRetract) {
						retract();
					} else if (c == cmdAbout) {
						about();
					}
				}
			}
		});
	}

	void load() {
		setFullScreenMode(true);
		cursorX = 4;
		cursorY = 6;
		sqSelected = mvLast = 0;
		if (midlet.rsData[0] == 0) {
			// pos.fromFen(Position.STARTUP_FEN[midlet.handicap]);
			pos.fromFen(midlet.txtFen.getString());
		} else {
			// Restore Record-Score Data
			pos.clearBoard();
			for (int sq = 0; sq < 128; sq ++) {
				int pc = midlet.rsData[sq + 256];
				if (pc > 0) {
					pos.addPiece(sq, pc);
				}
			}
			if (midlet.rsData[0] == 2) {
				pos.changeSide();
			}
			pos.setIrrev(midlet.rsData[384], midlet.rsData[385] & 255);
		}
		// Backup Retract Status
		System.arraycopy(midlet.rsData, 0, retractData, 0, ChessMIDlet.RS_DATA_LEN);
		// Call "responseMove()" if Computer Moves First
		phase = PHASE_LOADING;
		if (pos.sdPlayer == 0 ? midlet.moveMode == COMPUTER_WHITE :
				midlet.moveMode == COMPUTER_BLACK) {
			new Thread() {
				public void run() {
					while (phase == PHASE_LOADING) {
						try {
							sleep(100);
						} catch (InterruptedException e) {
							// Ignored
						}
					}
					responseMove();
				}
			}.start();
		}
	}

	protected void paint(Graphics g) {
		if (phase == PHASE_LOADING) {
			// Wait 1 second for resizing
			width = getWidth();
			height = getHeight();
			for (int i = 0; i < 10; i ++) {
				if (width != normalWidth || height != normalHeight) {
					break;
				}
				try {
					Thread.sleep(100);
				} catch (InterruptedException e) {
					// Ignored
				}
				width = getWidth();
				height = getHeight();
			}
			if (!init) {
				init = true;
				// "width" and "height" are Full-Screen values
				String imagePath = "/images/";
				squareSize = Math.min(width / 8, height / 8);
				if (squareSize >= 41) {
					squareSize = 41;
					imagePath += "large/";
				} else if (squareSize >= 29) {
					squareSize = 29;
					imagePath += "medium/";
				} else if (squareSize >= 21) {
					squareSize = 21;
					imagePath += "small/";
				} else {
					squareSize = 16;
					imagePath += "tiny/";
				}
				int boardSize = squareSize * 8;
				try {
					imgBoard = Image.createImage(imagePath + "board.png");
					imgSelected = Image.createImage(imagePath + "selected.png");
					imgCursor = Image.createImage(imagePath + "cursor.png");
					for (int pc = 0; pc < 24; pc ++) {
						if (IMAGE_NAME[pc] == null) {
							imgPieces[pc] = null;
						} else {
							imgPieces[pc] = Image.createImage(imagePath + IMAGE_NAME[pc] + ".png");
						}
					}
				} catch (Exception e) {
					throw new RuntimeException(e.getMessage());
				}
				left = (width - boardSize) / 2;
				top = (height - boardSize) / 2;
				right = left + boardSize - 32;
				bottom = top + boardSize - 32;
			}
			phase = PHASE_WAITING;
		}
		for (int x = 0; x < width; x += widthBackground) {
			for (int y = 0; y < height; y += heightBackground) {
				g.drawImage(imgBackground, x, y, Graphics.LEFT + Graphics.TOP);
			}
		}
		g.drawImage(imgBoard, width / 2, height / 2, Graphics.HCENTER + Graphics.VCENTER);
		for (int sq = 0; sq < 128; sq ++) {
			if (Position.IN_BOARD(sq)) {
				int pc = pos.squares[sq];
				if (pc > 0) {
					drawSquare(g, imgPieces[pc], sq);
				}
			}
		}
		int sqSrc = 0;
		int sqDst = 0;
		if (mvLast > 0) {
			sqSrc = Position.SRC(mvLast);
			sqDst = Position.DST(mvLast);
			drawSquare(g, imgSelected, sqSrc);
			drawSquare(g, imgSelected, sqDst);
		} else if (sqSelected > 0) {
			drawSquare(g, imgSelected, sqSelected);
		}
		int sq = Position.COORD_XY(cursorX + Position.FILE_LEFT, cursorY + Position.RANK_TOP);
		if (midlet.moveMode == COMPUTER_WHITE) {
			sq = Position.SQUARE_FLIP(sq);
		}
		drawSquare(g, imgCursor, sq);
		if (phase == PHASE_THINKING) {
			int x, y;
			if (midlet.moveMode == COMPUTER_WHITE) {
				x = (Position.FILE_X(sqDst) < 8 ? left : right);
				y = (Position.RANK_Y(sqDst) < 4 ? top : bottom);
			} else {
				x = (Position.FILE_X(sqDst) < 8 ? right: left);
				y = (Position.RANK_Y(sqDst) < 4 ? bottom: top);
			}
			g.drawImage(imgThinking, x, y, Graphics.LEFT + Graphics.TOP);
		} else if (phase == PHASE_EXITTING) {
			g.setFont(fontLarge);
			g.setColor(0xff0000);
			g.drawString(message, width / 2, height / 2, Graphics.HCENTER + Graphics.BASELINE);
		}

		if (hasPointerEvents()) {
			g.setFont(fontSmall);
			g.setColor(0x0000ff);
			g.drawString("Back", 0, height, Graphics.LEFT + Graphics.BASELINE);
			g.drawString("Retract", width / 2, height, Graphics.HCENTER + Graphics.BASELINE);
			g.drawString("About", width, height, Graphics.RIGHT + Graphics.BASELINE);
		}
	}

	protected void keyPressed(int code) {
		if (phase == PHASE_EXITTING) {
			midlet.startMusic("form");
			Display.getDisplay(midlet).setCurrent(midlet.form);
			return;
		}
		if (phase == PHASE_THINKING) {
			return;
		}

		int deltaX = 0, deltaY = 0;
		int action = getGameAction(code);
		if (action == FIRE || code == KEY_NUM5) {
			clickSquare();
		} else {
			switch (action) {
			case UP:
				deltaY = -1;
				break;
			case LEFT:
				deltaX = -1;
				break;
			case RIGHT:
				deltaX = 1;
				break;
			case DOWN:
				deltaY = 1;
				break;
			default:
				switch (code) {
				case KEY_NUM1:
					deltaX = -1;
					deltaY = -1;
					break;
				case KEY_NUM2:
					deltaY = -1;
					break;
				case KEY_NUM3:
					deltaX = 1;
					deltaY = -1;
					break;
				case KEY_NUM4:
					deltaX = -1;
					break;
				case KEY_NUM6:
					deltaX = 1;
					break;
				case KEY_NUM7:
					deltaX = -1;
					deltaY = 1;
					break;
				case KEY_NUM8:
					deltaY = 1;
					break;
				case KEY_NUM9:
					deltaX = 1;
					deltaY = 1;
					break;
				}
			}
			cursorX = (cursorX + deltaX + 8) % 8;
			cursorY = (cursorY + deltaY + 8) % 8;
		}
		repaint();
		serviceRepaints();
	}

	protected void pointerPressed(int x, int y) {
		if (phase == PHASE_EXITTING) {
			midlet.startMusic("form");
			Display.getDisplay(midlet).setCurrent(midlet.form);
			return;
		}
		if (phase == PHASE_THINKING) {
			return;
		}
		if (height - y < fontSmall.getHeight()) {
			switch (x * 3 / width) {
			case 0:
				back();
				return;
			case 1:
				retract();
				return;
			case 2:
				about();
				return;
			}
		}
		cursorX = Util.MIN_MAX(0, (x - left) / squareSize, 7);
		cursorY = Util.MIN_MAX(0, (y - top) / squareSize, 7);
		clickSquare();
		repaint();
		serviceRepaints();
	}

	private void clickSquare() {
		int sq = Position.COORD_XY(cursorX + Position.FILE_LEFT, cursorY + Position.RANK_TOP);
		if (midlet.moveMode == COMPUTER_WHITE) {
			sq = Position.SQUARE_FLIP(sq);
		}
		int pc = pos.squares[sq];
		if ((pc & Position.SIDE_TAG(pos.sdPlayer)) != 0) {
			midlet.playSound(RESP_CLICK);
			mvLast = 0;
			sqSelected = sq;
		} else {
			if (sqSelected > 0 && addMove(Position.MOVE(sqSelected, sq)) && !responseMove()) {
				midlet.rsData[0] = 0;
				phase = PHASE_EXITTING;
			}
		}
	}

	private void drawSquare(Graphics g, Image image, int sq) {
		int sqFlipped = (midlet.moveMode == COMPUTER_WHITE ? Position.SQUARE_FLIP(sq) : sq);
		int sqX = left + (Position.FILE_X(sqFlipped) - Position.FILE_LEFT) * squareSize;
		int sqY = top + (Position.RANK_Y(sqFlipped) - Position.RANK_TOP) * squareSize;
		g.drawImage(image, sqX, sqY, Graphics.LEFT + Graphics.TOP);
	}

	/** Player Move Result */
	private boolean getResult() {
		return getResult(midlet.moveMode == COMPUTER_NONE ?
				RESP_HUMAN_BOTH : RESP_HUMAN_SINGLE);
	}

	/** Computer Move Result */
	private boolean getResult(int response) {
		if (pos.isMate()) {
			if (pos.inCheck()) {
				midlet.playSound(response < 0 ? RESP_WIN : RESP_LOSS);
				message = (response < 0 ? "You Win!" : "You Lose!");
			} else {
				midlet.playSound(RESP_DRAW);
				message = "Draw by Stalemate!";
			}
			return true;
		}
		if (pos.isRep(2)) {
			midlet.playSound(RESP_DRAW);
			message = "Draw by Repetition!";
			return true;
		}
		if (pos.moveNum > 100) {
			midlet.playSound(RESP_DRAW);
			message = "Draw by 50-Move Rule!";
			return true;
		}
		if (response != RESP_HUMAN_SINGLE) {
			if (response >= 0) {
				midlet.playSound(response);
			}
			// Backup Retract Status
			System.arraycopy(midlet.rsData, 0, retractData, 0, ChessMIDlet.RS_DATA_LEN);
			// Backup Record-Score Data
			midlet.rsData[0] = (byte) (pos.sdPlayer + 1);
			System.arraycopy(pos.squares, 0, midlet.rsData, 256, 128);
			midlet.rsData[384] = (byte) pos.castlingBits();
			midlet.rsData[385] = (byte) pos.enPassantSquare();
		}
		return false;
	}

	private boolean addMove(int mv) {
		if (pos.legalMove(mv)) {
			int pcSrc = pos.squares[Position.SRC(mv)];
			if (pos.makeMove(mv)) {
				midlet.playSound(pos.inCheck() ? RESP_CHECK : pos.specialMove() ?
						RESP_SPECIAL : pos.captured() ? RESP_CAPTURE : RESP_MOVE);
				if (pos.captured() || Position.PIECE_TYPE(pcSrc) == Position.PIECE_PAWN) {
					pos.setIrrev();
				}
				sqSelected = 0;
				mvLast = mv;
				return true;
			}
			midlet.playSound(RESP_ILLEGAL);
		}
		return false;
	}

	boolean responseMove() {
		if (getResult()) {
			return false;
		}
		if (midlet.moveMode == COMPUTER_NONE) {
			return true;
		}
		phase = PHASE_THINKING;
		repaint();
		serviceRepaints();
		mvLast = search.searchMain(1000 << (midlet.level << 1));
		int pc = pos.squares[Position.SRC(mvLast)];
		pos.makeMove(mvLast);
		int response = pos.inCheck() ? RESP_CHECK2 : pos.specialMove() ?
				RESP_SPECIAL2 : pos.captured() ? RESP_CAPTURE2 : RESP_MOVE2;
		if (pos.captured() || Position.PIECE_TYPE(pc) == Position.PIECE_PAWN) {
			pos.setIrrev();
		}
		phase = PHASE_WAITING;
		repaint();
		serviceRepaints();
		return !getResult(response);
	}

	void back() {
		if (phase == PHASE_WAITING) {
			Display.getDisplay(midlet).setCurrent(altBack);
		} else {
			midlet.rsData[0] = 0;
			midlet.startMusic("form");
			Display.getDisplay(midlet).setCurrent(midlet.form);
		}
	}

	void retract() {
		// Restore Retract Status
		System.arraycopy(retractData, 0, midlet.rsData, 0, ChessMIDlet.RS_DATA_LEN);
		load();
		repaint();
		serviceRepaints();
	}

	void about() {
		Display.getDisplay(midlet).setCurrent(altAbout);
		phase = PHASE_LOADING;
		setFullScreenMode(true);
	}
}
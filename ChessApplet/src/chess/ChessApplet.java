/*
ChessApplet.java - Source Code for Mobile Chess, Part IV

Mobile Chess - a Chess Program for Java ME
Designed by Morning Yellow, Version: 1.05, Last Modified: Apr. 2008
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
package chess;

import java.applet.Applet;
import java.applet.AudioClip;
import java.awt.Button;
import java.awt.Canvas;
import java.awt.Checkbox;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Graphics;
import java.awt.Image;
import java.awt.Label;
import java.awt.List;
import java.awt.Scrollbar;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.AdjustmentEvent;
import java.awt.event.AdjustmentListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;

public class ChessApplet extends Applet {
	private static final long serialVersionUID = 1L;

	private static final int RESP_CLICK = 0;
	private static final int RESP_ILLEGAL = 1;
	private static final int RESP_MOVE = 2;
	private static final int RESP_MOVE2 = 3;
	private static final int RESP_CAPTURE = 4;
	private static final int RESP_CAPTURE2 = 5;
	private static final int RESP_CHECK = 6;
	private static final int RESP_CHECK2 = 7;
	private static final int RESP_SPECIAL = 8;
	private static final int RESP_SPECIAL2 = 9;
	private static final int RESP_WIN = 10;
	private static final int RESP_DRAW = 11;
	private static final int RESP_LOSS = 12;

	private static final int PIECE_MARGIN = 4;
	private static final int SQUARE_SIZE = 41;
	private static final int BOARD_SIZE = 336;
	private static final int ITEM_WIDTH = 100;
	private static final int ITEM_HEIGHT = 20;

	private static final String[] PIECE_NAME = {
		null, null, null, null, null, null, null, null,
		"wk", "wq", "wr", "wb", "wn", "wp", null, null,
		"bk", "bq", "br", "bb", "bn", "bp", null, null,
	};

	private static final String[] SOUND_NAME = {
		"click", "illegal", "move", "move2", "capture", "capture2",
		"check", "check2", "special", "special2", "win", "draw", "loss"
	};

	static final String[] LEVEL_TEXT = {
		"Beginner", "Amateur", "Expert", "Master", "Grand Master"
	};

	Image[] imgPieces = new Image[PIECE_NAME.length];
	Image imgSelected, imgBoard;
	AudioClip[] acSounds = new AudioClip[SOUND_NAME.length];
	AudioClip acMusic;

	Canvas canvas = new Canvas() {
		private static final long serialVersionUID = 1L;

		public void paint(Graphics g) {
			g.drawImage(imgBoard, 0, 0, this);
			for (int x = Position.FILE_LEFT; x <= Position.FILE_RIGHT; x ++) {
				for (int y = Position.RANK_TOP; y <= Position.RANK_BOTTOM; y ++) {
					int sq = Position.COORD_XY(x, y);
					sq = (flipped ? Position.SQUARE_FLIP(sq) : sq);
					int xx = PIECE_MARGIN + (x - Position.FILE_LEFT) * SQUARE_SIZE;
					int yy = PIECE_MARGIN + (y - Position.RANK_TOP) * SQUARE_SIZE;
					int pc = pos.squares[sq];
					if (pc > 0) {
						g.drawImage(imgPieces[pc], xx, yy, this);
					}
					if (sq == sqSelected || sq == Position.SRC(mvLast) ||
							sq == Position.DST(mvLast)) {
						g.drawImage(imgSelected, xx, yy, this);
					}
				}
			}
		}
	};
	Button btnMessage = new Button();

	Position pos = new Position();
	Search search = new Search(pos, 16);
	String currentFen = Position.STARTUP_FEN[0], retractFen;
	int sqSelected, mvLast;

	volatile boolean thinking = false;
	boolean flipped = false, effect = true, music = true;
	int handicap = 0, level = 0;

	{
		setLayout(null);

		btnMessage.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				currentFen = Position.STARTUP_FEN[handicap];
				restart();
				canvas.repaint();
			}
		});
		btnMessage.setBounds(BOARD_SIZE / 4, (BOARD_SIZE - ITEM_HEIGHT) / 2,
				BOARD_SIZE / 2, ITEM_HEIGHT);
		btnMessage.setVisible(false);
		add(btnMessage);

		canvas.addMouseListener(new MouseListener() {
			public void mouseClicked(MouseEvent e) {
				// Do Nothing
			}

			public void mouseEntered(MouseEvent e) {
				// Do Nothing
			}

			public void mouseExited(MouseEvent e) {
				// Do Nothing
			}

			public void mousePressed(MouseEvent e) {
				if (!thinking && !btnMessage.isVisible()) {
					int x = Util.MIN_MAX(0, (e.getX() - PIECE_MARGIN) / SQUARE_SIZE, 8);
					int y = Util.MIN_MAX(0, (e.getY() - PIECE_MARGIN) / SQUARE_SIZE, 9);
					clickSquare(Position.COORD_XY(x + Position.FILE_LEFT, y + Position.RANK_TOP));
				}
			}

			public void mouseReleased(MouseEvent e) {
				// Do Nothing
			}
		});
		canvas.setBounds(0, 0, BOARD_SIZE, BOARD_SIZE);
		add(canvas);

		addItem("Player Takes:", 0);
		final List optFlipped = new List(2);
		optFlipped.add("White");
		optFlipped.add("Black");
		optFlipped.select(flipped ? 1 : 0);
		addItem(optFlipped, 1, 2);

		addItem("White Offers:", 3);
		final List optHandicap = new List(4);
		optHandicap.add("No Odds");
		optHandicap.add("A Knight Odds");
		optHandicap.add("A Rook Odds");
		optHandicap.add("A Queen Odds");
		optHandicap.select(handicap);
		addItem(optHandicap, 4, 4);

		Button btnRestart = new Button("Restart");
		btnRestart.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (!thinking) {
					flipped = (optFlipped.getSelectedIndex() == 1);
					handicap = optHandicap.getSelectedIndex();
					currentFen = Position.STARTUP_FEN[handicap];
					restart();
					canvas.repaint();
				}
			}
		});
		addItem(btnRestart, 8);

		Button btnRetract = new Button("Retract");
		btnRetract.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (!thinking) {
					currentFen = retractFen;
					restart();
					canvas.repaint();
				}
			}
		});
		addItem(btnRetract, 9);

		final Label lblLevel = new Label("Level: " + LEVEL_TEXT[level]);
		addItem(lblLevel, 10);
		final Scrollbar sbLevel = new Scrollbar(Scrollbar.HORIZONTAL, level, 1, 0, 5);
		sbLevel.addAdjustmentListener(new AdjustmentListener() {
			public void adjustmentValueChanged(AdjustmentEvent e) {
				level = sbLevel.getValue();
				lblLevel.setText("Level: " + LEVEL_TEXT[level]);
			}
		});
		addItem(sbLevel, 11);

		final Checkbox chkSound = new Checkbox("Sound", effect);
		chkSound.addItemListener(new ItemListener() {
			public void itemStateChanged(ItemEvent e) {
				effect = chkSound.getState();
				playSound(0);
			}
		});
		addItem(chkSound, -2);

		final Checkbox chkMusic = new Checkbox("Music", music);
		chkMusic.addItemListener(new ItemListener() {
			public void itemStateChanged(ItemEvent e) {
				music = chkMusic.getState();
				if (music) {
					startMusic();
				} else {
					stopMusic();
				}
			}
		});
		addItem(chkMusic, -1);
	}

	public void init() {
		loadBoard();
		loadPieces();
		for (int i = 0; i < SOUND_NAME.length; i ++) {
			acSounds[i] = getAudioClip(getCodeBase(), "sounds/" + SOUND_NAME[i] + ".wav");
		}
		startMusic();
		restart();
	}

	public void destroy() {
		stopMusic();
	}

	void addItem(String label, int top) {
		addItem(new Label(label), top);
	}

	void addItem(Component component, int top) {
		addItem(component, top, 1);
	}

	void addItem(Component component, int top, int height) {
		if (top < 0) {
			component.setBounds(BOARD_SIZE, BOARD_SIZE + ITEM_HEIGHT * top, ITEM_WIDTH, ITEM_HEIGHT * height);
		} else {
			component.setBounds(BOARD_SIZE, ITEM_HEIGHT * top, ITEM_WIDTH, ITEM_HEIGHT * height);
		}
		add(component);
	}

	void loadBoard() {
		imgBoard = getImage(getCodeBase(), "board.gif");
	}

	void loadPieces() {
		for (int i = 0; i < PIECE_NAME.length; i ++) {
			imgPieces[i] = (PIECE_NAME[i] == null ? null : getImage(getCodeBase(),
					"pieces/" + PIECE_NAME[i] + ".gif"));
		}
		imgSelected = getImage(getCodeBase(), "pieces/oos.gif");
	}

	void startMusic() {
		acMusic = getAudioClip(getCodeBase(), "bg.mid");
		if (acMusic != null) {
			acMusic.loop();
		}
	}

	void stopMusic() {
		if (acMusic != null) {
			acMusic.stop();
		}
	}

	void restart() {
		btnMessage.setVisible(false);
		pos.fromFen(currentFen);
		retractFen = currentFen;
		sqSelected = mvLast = 0;
		if (flipped && pos.sdPlayer == 0) {
			thinking();
		}
	}

	void clickSquare(int sq_) {
		int sq = (flipped ? Position.SQUARE_FLIP(sq_) : sq_);
		int pc = pos.squares[sq];
		if ((pc & Position.SIDE_TAG(pos.sdPlayer)) != 0) {
			if (sqSelected > 0) {
				drawSquare(sqSelected);
			}
			if (mvLast > 0) {
				drawMove(mvLast);
				mvLast = 0;
			}
			sqSelected = sq;
			drawSquare(sq);
			playSound(RESP_CLICK);
		} else if (sqSelected > 0) {
			int mv = Position.MOVE(sqSelected, sq);
			if (!pos.legalMove(mv)) {
				return;
			}
			pc = pos.squares[sqSelected];
			if (!pos.makeMove(mv)) { // pos.sdPlayer Changed!!!
				playSound(RESP_ILLEGAL);
				return;
			}
			if (pos.specialMove()) {
				if (Position.PIECE_TYPE(pc) == Position.PIECE_KING) {
					int castling = Position.
							CASTLING_TYPE(1 - pos.sdPlayer, sqSelected, sq);
					drawSquare(Position.CASTLING_ROOK_SRC[castling]);
					drawSquare(Position.CASTLING_ROOK_DST[castling]);
				} else {
					drawSquare(sq - Position.FORWARD_DELTA(1 - pos.sdPlayer));
				}
			}
			int response = pos.inCheck() ? RESP_CHECK : pos.specialMove() ?
					RESP_SPECIAL : pos.captured() ? RESP_CAPTURE : RESP_MOVE;
			if (pos.captured() || Position.PIECE_TYPE(pc) == Position.PIECE_PAWN) {
				pos.setIrrev();
			}
			mvLast = mv;
			sqSelected = 0;
			drawMove(mv);
			playSound(response);
			if (!getResult()) {
				thinking();
			}
		}
	}

	void drawSquare(int sq_) {
		int sq = (flipped ? Position.SQUARE_FLIP(sq_) : sq_);
		int x = PIECE_MARGIN + (Position.FILE_X(sq) - Position.FILE_LEFT) * SQUARE_SIZE;
		int y = PIECE_MARGIN + (Position.RANK_Y(sq) - Position.RANK_TOP) * SQUARE_SIZE;
		canvas.repaint(x, y, SQUARE_SIZE, SQUARE_SIZE);
	}

	void drawMove(int mv) {
		drawSquare(Position.SRC(mv));
		drawSquare(Position.DST(mv));
	}

	void playSound(int response) {
		if (effect && acSounds[response] != null) {
			acSounds[response].play();
		}
	}

	void showMessage(String message) {
		btnMessage.setLabel(message);
		btnMessage.setVisible(true);
	}

	void thinking() {
		thinking = true;
		new Thread() {
			public void run() {
				setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
				int mv = mvLast;
				mvLast = search.searchMain(100 << (level << 1));
				int sqSrc = Position.SRC(mvLast);
				int sqDst = Position.DST(mvLast);
				int pc = pos.squares[sqSrc];
				pos.makeMove(mvLast); // pos.sdPlayer Changed!!!
				drawMove(mv);
				drawMove(mvLast);
				if (pos.specialMove()) {
					if (Position.PIECE_TYPE(pc) == Position.PIECE_KING) {
						int castling = Position.CASTLING_TYPE(1 - pos.sdPlayer, sqSrc, sqDst);
						drawSquare(Position.CASTLING_ROOK_SRC[castling]);
						drawSquare(Position.CASTLING_ROOK_DST[castling]);
					} else {
						drawSquare(sqDst - Position.FORWARD_DELTA(1 - pos.sdPlayer));
					}
				}
				int response = pos.inCheck() ? RESP_CHECK2 : pos.specialMove() ?
						RESP_SPECIAL2 : pos.captured() ? RESP_CAPTURE2 : RESP_MOVE2;
				if (pos.captured() || Position.PIECE_TYPE(pc) == Position.PIECE_PAWN) {
					pos.setIrrev(); // pos.specialMove() Changed!!!
				}
				setCursor(Cursor.getPredefinedCursor(Cursor.DEFAULT_CURSOR));
				getResult(response);
				thinking = false;
			}
		}.start();
	}

	/** Player Move Result */
	boolean getResult() {
		return getResult(-1);
	}

	/** Computer Move Result */
	boolean getResult(int response) {
		if (pos.isMate()) {
			if (pos.inCheck()) {
				playSound(response < 0 ? RESP_WIN : RESP_LOSS);
				showMessage(response < 0 ? "You Win!" : "You Lose!");
			} else {
				playSound(RESP_DRAW);
				showMessage("Draw by Stalemate!");
			}
			return true;
		}
		if (pos.isRep(2)) {
			playSound(RESP_DRAW);
			showMessage("Draw by Repetition!");
			return true;
		}
		if (pos.moveNum > 100) {
			playSound(RESP_DRAW);
			showMessage("Draw by 50-Move Rule!");
			return true;
		}
		if (response >= 0) {
			playSound(response);
			retractFen = currentFen;
			currentFen = pos.toFen();
		}
		return false;
	}
}
package chess.book;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;

import chess.Position;

public class MoveList extends ArrayList<Integer> {
	private static final long serialVersionUID = 1L;

	private int result = 0;

	private static int MOVE(int sqSrc, int sqDst) {
		return Position.MOVE(sqSrc, sqDst);
	}

	private static int COORD_XY(int x, int y) {
		return Position.COORD_XY(x, y);
	}

	private static int parseMove(Position pos, int pt, String strMove) {
		if (pt == Position.PIECE_KING && strMove.charAt(0) == 'O') {
			int castling = (pos.sdPlayer << 1) + (strMove.startsWith("O-O-O") ? 1 : 0);
			return MOVE(Position.CASTLING_KING_SRC[castling], Position.CASTLING_KING_DST[castling]);
		}
		int xSrc = -1, ySrc = -1, xDst = -1, yDst = -1;
		for (int i = strMove.length() - 1; i >= 0; i --) {
			char c = strMove.charAt(i);
			if (c >= '1' && c <= '8') {
				if (yDst == -1) {
					yDst = Position.RANK_TOP + ('8' - c);
				} else {
					ySrc = Position.RANK_TOP + ('8' - c);
				}
			} else if (c >= 'a' && c <= 'h') {
				if (xDst == -1) {
					xDst = Position.FILE_LEFT + (c - 'a');
				} else {
					xSrc = Position.FILE_LEFT + (c - 'a');
				}
			}
		}
		if (xDst == -1 || yDst == -1) {
			return 0;
		}
		int sqDst = COORD_XY(xDst, yDst);
		if (xSrc != -1 && ySrc != -1) {
			return MOVE(COORD_XY(xSrc, ySrc), sqDst);
		}
		int pc = Position.SIDE_TAG(pos.sdPlayer) + pt;
		if (xSrc != -1) {
			for (ySrc = Position.RANK_TOP; ySrc <= Position.RANK_BOTTOM; ySrc ++) {
				int sqSrc = COORD_XY(xSrc, ySrc);
				if (pos.squares[sqSrc] == pc) {
					int mv = MOVE(sqSrc, sqDst);
					if (pos.legalMove(mv)) {
						return mv;
					}
				}
			}
			return 0;
		}
		if (ySrc != -1) {
			for (xSrc = Position.FILE_LEFT; xSrc <= Position.FILE_RIGHT; xSrc ++) {
				int sqSrc = COORD_XY(xSrc, ySrc);
				if (pos.squares[sqSrc] == pc) {
					int mv = MOVE(sqSrc, sqDst);
					if (pos.legalMove(mv)) {
						return mv;
					}
				}
			}
			return 0;
		}
		for (int sqSrc = 0; sqSrc < 128; sqSrc ++) {
			if (Position.IN_BOARD(sqSrc) && pos.squares[sqSrc] == pc) {
				int mv = MOVE(sqSrc, sqDst);
				if (pos.legalMove(mv)) {
					return mv;
				}
			}
		}
		return 0;
	}

	public MoveList(String file, Position pos) throws Exception {
		pos.fromFen(Position.STARTUP_FEN[0]);
		boolean returned = false, detail = false;
		int remLevel = 0;
		BufferedReader in;
		try {
			in = new BufferedReader(new FileReader(file));
		} catch (Exception e) {
			return;
		}
		String s;
		s = in.readLine();
		if (s == null) {
			in.close();
			return;
		}
		int index = 0;
		while (true) {
			if (detail) {
				if (remLevel > 0) {
					boolean endFor = true;
					while (index < s.length()) {
						char c = s.charAt(index);
						index ++;
						remLevel += (c == '(' || c == '{' ? 1 : c == ')' || c == '}' ? -1 : 0);
						if (remLevel == 0) {
							endFor = false;
							break;
						}
					}
					if (endFor) {
						returned = true;
					}
				} else {
					boolean endFor = true;
					while (index < s.length()) {
						char c = s.charAt(index);
						index ++;
						if (c == '(' || c == '{') {
							remLevel ++;
							endFor = false;
						} else if (c == ' ') {
							// Do Nothing
						} else {
							int indexSpace = s.indexOf(' ', index);
							if (indexSpace < 0) {
								indexSpace = s.length();
							}
							int indexVariant = s.indexOf('(', index);
							if (indexVariant < 0) {
								indexVariant = s.length();
							}
							int indexComment = s.indexOf('{', index);
							if (indexComment < 0) {
								indexComment = s.length();
							}
							int indexBreak = Math.min(indexSpace, Math.min(indexVariant, indexComment));
							String strMove = s.substring(index - 1, indexBreak);
							index = (indexBreak == indexSpace ? indexSpace + 1 : indexBreak);

							int mv = 0;
							int n = "KQRBN".indexOf(c);
							if (n < 0) {
								if (c >= 'a' && c <= 'h') {
									mv = parseMove(pos, Position.PIECE_PAWN, strMove);
								} else if (c == 'O') {
									mv = parseMove(pos, Position.PIECE_KING, strMove);
								}
							} else {
								mv = parseMove(pos, n, strMove.substring(1));
							}
							if (mv > 0 && pos.legalMove(mv) && pos.makeMove(mv)) {
								add(Integer.valueOf(mv));
								if (pos.captured() || pos.specialMove()) {
									pos.setIrrev();
								}
							}
						}
						if (!endFor) {
							break;
						}
					}
					if (endFor) {
						returned = true;
					}
				}
			} else {
				if (s.length() == 0) {
					returned = true;
				} else if (s.charAt(0) == '[') {
					if (s.toUpperCase().startsWith("[RESULT \"")) {
						int n = s.indexOf("\"]");
						if (n > 0) {
							s = s.substring(9, n);
							result = s.equals("*") ? 0 : s.equals("1-0") ? 1 :
									s.equals("1/2-1/2") ? 2 : s.equals("0-1") ? 3 : 0;
						}
					}
					returned = true;
				} else {
					detail = true;
				}
			}
			if (returned) {
				s = in.readLine();
				if (s == null) {
					in.close();
					return;
				}
				index = 0;
				returned = false;
			}
		}
	}

	public int getResult() {
		return result;
	}
}
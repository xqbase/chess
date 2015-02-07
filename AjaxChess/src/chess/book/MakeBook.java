package chess.book;

import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.TreeSet;

import ajaxchess.util.Bytes;
import chess.Position;

class TempItem {
	int zobristLock, zobristKey, mv;

	TempItem(Position pos, int mv) {
		zobristLock = pos.zobristLock;
		zobristKey = pos.zobristKey;
		this.mv = mv;
	}

	@Override
	public boolean equals(Object obj) {
		if (obj instanceof TempItem) {
			TempItem o = (TempItem) obj;
			return zobristLock == o.zobristLock && zobristKey == o.zobristKey && mv == o.mv;
		}
		return false;
	}

	@Override
	public int hashCode() {
		return zobristLock ^ zobristKey ^ mv;
	}
}

class BookItem implements Comparable<BookItem> {
	int zobristLock;
	short mv, vl;

	BookItem(TempItem tempItem, int vl) {
		zobristLock = tempItem.zobristLock;
		mv = (short) tempItem.mv;
		this.vl = (short) vl;
	}

	public int compareTo(BookItem o) {
		int compareValue = (zobristLock >>> 1) - (o.zobristLock >>> 1);
		if (compareValue == 0) {
			return mv - o.mv;
		}
		return compareValue;
	}
}

public class MakeBook {
	private static int moveValue(int sd, int result) {
		switch (result) {
		case 1:
			return sd == 0 ? 3 : -1;
		case 2:
			return 1;
		case 3:
			return sd == 0 ? -1 : 3;
		default:
			return 0;
		}
	}

	public static void main(String[] args) throws Exception {
		Position pos = new Position();
		HashMap<TempItem, Integer> mapTemp = new HashMap<TempItem, Integer>();
		for (int i = 1; i <= 14433; i ++) {
			MoveList lstMove = new MoveList("D:\\CBL\\CBL" + Integer.toString(100000 + i).substring(1) + ".PGN", pos);
			pos.fromFen(Position.STARTUP_FEN[0]);
			for (Integer mv : lstMove) {
				TempItem tempItem = new TempItem(pos, mv.intValue());
				int vl = moveValue(pos.sdPlayer, lstMove.getResult());
				if (mapTemp.get(tempItem) != null) {
					vl += mapTemp.get(tempItem).intValue();
				}
				mapTemp.put(tempItem, Integer.valueOf(vl));
				pos.makeMove(mv.intValue());
				if (pos.captured() || pos.specialMove()) {
					pos.setIrrev();
				}
			}
		}
		TreeSet<BookItem> setBook = new TreeSet<BookItem>();
		for (TempItem tempItem : mapTemp.keySet()) {
			int vl = mapTemp.get(tempItem).intValue();
			if (vl >= 4) {
				setBook.add(new BookItem(tempItem, vl >> 2));
			}
		}
		FileOutputStream out = new FileOutputStream("D:\\BOOK.DAT");
		for (BookItem bookItem : setBook) {
			out.write(Bytes.fromInt(bookItem.zobristLock, Bytes.LITTLE_ENDIAN));
			out.write(Bytes.fromShort(bookItem.mv, Bytes.LITTLE_ENDIAN));
			out.write(Bytes.fromShort(bookItem.vl, Bytes.LITTLE_ENDIAN));
		}
		out.close();
	}
}
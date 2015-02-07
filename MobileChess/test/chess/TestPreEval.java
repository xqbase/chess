package chess;

public class TestPreEval {
	public static void main(String[] args) {
		Position pos = new Position();
		pos.fromFen("8/7p/5k2/5p2/p1p2P2/Pr1pPK2/1P1R3P/8 b - - bm Rxb2; id WAC002;");
		pos.printBoard();
		Evaluate.preEval(pos);
		for (int y = Position.RANK_TOP; y <= Position.RANK_BOTTOM; y ++) {
			for (int x = Position.FILE_LEFT; x <= Position.FILE_RIGHT; x ++) {
				int sq = Position.COORD_XY(x, y);
				System.out.print(pos.vlWhitePiecePos[5][sq] + "\t");
			}
			System.out.println();
		}
		System.out.println("vlWhite = " + pos.vlWhite);
		System.out.println("vlBlack = " + pos.vlBlack);
	}
}
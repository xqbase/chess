package chess;

public class TestBug {
	public static void main(String[] args) {
		Position pos = new Position();
		pos.fromFen("r1b1k2r/3pnp2/4p3/ppP2p1p/3PP2P/6P1/P2N1P2/R2BK2R w KQkq - 0 1");
		System.out.println("Before Player Moves:");
		pos.printBoard();
		String moveStr = "a2a4";
		System.out.println("Player Moves " + moveStr + " ...");
		pos.makeMove(Position.PARSE_MOVE(moveStr));
		System.out.println("After Player Moves:");
		pos.printBoard();
		System.out.println("Computer Thinks ...");
		Search search = new Search(pos, 12);
		int mv = search.searchMain(8, 60000);
		System.out.println("After Computer Thinks:");
		pos.printBoard();
		System.out.println("Computer Moves " + Position.MOVE_STR(mv) + " ...");
		pos.makeMove(mv);
		System.out.println("After Computer Moves:");
		pos.printBoard();
	}
}
package ajaxchess.web;

import java.util.Arrays;
import java.util.List;

public class Choices {
	public static final String FLIPPED_FALSE = "White";
	public static final String FLIPPED_TRUE = "Black";

	private static List<String> lstFlipped = Arrays.asList(new String[] {
		FLIPPED_FALSE, FLIPPED_TRUE
	});

	public static List<String> getFlippedTypes() {
		return lstFlipped;
	}

	private static List<String> lstHandicap = Arrays.asList(new String[] {
		"None", "A Knight Odds", "A Rook Odds", "A Queen Odds"
	});

	public static List<String> getHandicapTypes() {
		return lstHandicap;
	}
}
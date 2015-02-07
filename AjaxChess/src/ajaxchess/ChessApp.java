package ajaxchess;

import org.apache.wicket.protocol.http.WebApplication;

import ajaxchess.util.wicket.RefreshPage;
import ajaxchess.web.ChessPage;

public class ChessApp extends WebApplication {
	@Override
	public Class<? extends ChessPage> getHomePage() {
		return ChessPage.class;
	}

	@Override
	protected void init() {
		getApplicationSettings().setPageExpiredErrorPage(RefreshPage.class);
	}
}
/*
ChessMIDlet.java - Source Code for Mobile Chess, Part III

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

import java.io.InputStream;

import javax.microedition.lcdui.Choice;
import javax.microedition.lcdui.ChoiceGroup;
import javax.microedition.lcdui.Command;
import javax.microedition.lcdui.CommandListener;
import javax.microedition.lcdui.Display;
import javax.microedition.lcdui.Displayable;
import javax.microedition.lcdui.Form;
import javax.microedition.lcdui.Gauge;
import javax.microedition.lcdui.Item;
import javax.microedition.lcdui.ItemStateListener;
import javax.microedition.lcdui.TextField;
import javax.microedition.lcdui.Ticker;
import javax.microedition.media.Manager;
import javax.microedition.media.Player;
import javax.microedition.media.control.VolumeControl;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.RecordEnumeration;
import javax.microedition.rms.RecordStore;

public class ChessMIDlet extends MIDlet {
	private static final String STORE_NAME = "MobileChess";

	static final String[] SOUND_NAME = {
		"click", "illegal", "move", "move2", "capture", "capture2",
		"special", "special2", "check", "check2", "win", "draw", "loss", "newgame",
	};

	static final int RS_DATA_LEN = 512;

	/**
	 * 0: Status, 0 = Startup Form, 1 = Red To Move, 2 = Black To Move<br>
	 * 16: Player, 0 = White, 1 = Black (Flipped), 2 = Both<br>
	 * 17: Handicap, 0 = None, 1 = Knight, 2 = Rook, 3 = Queen<br>
	 * 18: Level, 0 = Beginner, 1 = Amateur, 2 = Expert<br>
	 * 19: Sound Level, 0 = Mute, 5 = Max<br>
	 * 20: Music Level, 0 = Mute, 5 = Max<br>
	 * 256-383: Squares<br>
	 * 384: Castling Bits<br>
	 * 385: En-Passant Square
	 */
	byte[] rsData = new byte[RS_DATA_LEN];
	int moveMode, handicap, level, sound, music;
	Player midiPlayer = null;
	Form form = new Form("Mobile Chess");
	ChessCanvas canvas = new ChessCanvas(this);

	private boolean started = false;

	Command cmdStart = new Command("Start", Command.OK, 1);
	Command cmdExit = new Command("Exit", Command.BACK, 1);

	ChoiceGroup cgMoveMode = new ChoiceGroup("My Color", Choice.EXCLUSIVE,
				new String[] {"White", "Black", "Both"}, null);
	ChoiceGroup cgHandicap = new ChoiceGroup("Handicap", Choice.POPUP,
				new String[] {"None", "a Knight", "a Rook", "a Queen"}, null);
	ChoiceGroup cgLevel = new ChoiceGroup("Level", Choice.POPUP,
				new String[] {"Beginner", "Amateur", "Expert"}, null);
	Gauge gSound = new Gauge("Sound Effect", true, 5, 0);
	Gauge gMusic = new Gauge("Background Music", true, 5, 0);
	TextField txtFen = new TextField("Startup FEN", null, 128, TextField.ANY);

	{
		form.append(cgMoveMode);
		form.append(cgHandicap);
		form.append(cgLevel);
		form.append(gSound);
		form.append(gMusic);
		form.addCommand(cmdStart);
		form.addCommand(cmdExit);
		if (getAppProperty("MobileChess-Debug").toLowerCase().equals("true")) {
			form.append(txtFen);
		}
		form.setTicker(new Ticker("Welcome to http://www.chess-wizard.com/"));

		form.setCommandListener(new CommandListener() {
			public void commandAction(Command c, Displayable d) {
				if (c == cmdStart) {
					moveMode = cgMoveMode.getSelectedIndex();
					handicap = cgHandicap.getSelectedIndex();
					level = cgLevel.getSelectedIndex();
					sound = gSound.getValue();
					music = gMusic.getValue();
					canvas.load();
					playSound(SOUND_NAME.length - 1);
					startMusic("canvas");
					Display.getDisplay(ChessMIDlet.this).setCurrent(canvas);
				} else if (c == cmdExit) {
					destroyApp(false);
					notifyDestroyed();
				}
			}
		});

		form.setItemStateListener(new ItemStateListener() {
			public void itemStateChanged(Item i) {
				if (i == cgHandicap) {
					txtFen.setString(Position.STARTUP_FEN[cgHandicap.getSelectedIndex()]);
				} else if (i == gSound) {
					sound = gSound.getValue();
					playSound(0);
				} else if (i == gMusic) {
					int originalMusic = music;
					music = gMusic.getValue();
					if (music == 0) {
						stopMusic();
					} else if (originalMusic == 0) {
						startMusic("form");
					} else {
						setMusicVolume();
					}
				}
			}
		});
	}

	public void startApp() {
		if (started) {
			return;
		}
		started = true;
		for (int i = 0; i < RS_DATA_LEN; i ++) {
			rsData[i] = 0;
		}
		rsData[19] = 3;
		rsData[20] = 2;
		try {
			RecordStore rs = RecordStore.openRecordStore(STORE_NAME, true);
			RecordEnumeration re = rs.enumerateRecords(null, null, false);
			if (re.hasNextElement()) {
				int recordId = re.nextRecordId();
				if (rs.getRecordSize(recordId) == RS_DATA_LEN) {
					rsData = rs.getRecord(recordId);
				} else {
					rs.setRecord(recordId, rsData, 0, RS_DATA_LEN);
				}
			} else {
				rs.addRecord(rsData, 0, RS_DATA_LEN);
			}
			rs.closeRecordStore();
		} catch (Exception e) {
			// Ignored
		}
		moveMode = Util.MIN_MAX(0, rsData[16], 2);
		handicap = Util.MIN_MAX(0, rsData[17], 3);
		level = Util.MIN_MAX(0, rsData[18], 2);
		sound = Util.MIN_MAX(0, rsData[19], 5);
		music = Util.MIN_MAX(0, rsData[20], 5);
		cgMoveMode.setSelectedIndex(moveMode, true);
		cgLevel.setSelectedIndex(level, true);
		cgHandicap.setSelectedIndex(handicap, true);
		gSound.setValue(sound);
		gMusic.setValue(music);
		txtFen.setString(Position.STARTUP_FEN[handicap]);
		if (rsData[0] == 0) {
			startMusic("form");
			Display.getDisplay(this).setCurrent(form);
		} else {
			canvas.load();
			startMusic("canvas");
			Display.getDisplay(this).setCurrent(canvas);
		}
	}

	public void pauseApp() {
		// Do Nothing
	}

	public void destroyApp(boolean unc) {
		stopMusic();
		rsData[16] = (byte) moveMode;
		rsData[17] = (byte) handicap;
		rsData[18] = (byte) level;
		rsData[19] = (byte) sound;
		rsData[20] = (byte) music;
		try {
			RecordStore rs = RecordStore.openRecordStore(STORE_NAME, true);
			RecordEnumeration re = rs.enumerateRecords(null, null, false);
			if (re.hasNextElement()) {
				int recordId = re.nextRecordId();
				rs.setRecord(recordId, rsData, 0, RS_DATA_LEN);
			} else {
				rs.addRecord(rsData, 0, RS_DATA_LEN);
			}
			rs.closeRecordStore();
		} catch (Exception e) {
			// Ignored
		}
		started = false;
	}

	Player createPlayer(String name, String type) {
		InputStream in = getClass().getResourceAsStream(name);
		try {
			return Manager.createPlayer(in, type);
			// If creating "Player" succeeded, no need to close "InputStream".
		} catch (Exception e) {
			try {
				in.close();
			} catch (Exception e2) {
				// Ignored
			}
			return null;
		}
	}

	void playSound(int response) {
		if (sound == 0) {
			return;
		}
		final int i = response;
		new Thread() {
			public void run() {
				Player p = createPlayer("/sounds/" + SOUND_NAME[i] + ".wav", "audio/x-wav");
				if (p == null) {
					return;
				}
				try {
					p.realize();
					VolumeControl vc = (VolumeControl) p.getControl("VolumeControl");
					if (vc != null) {
						vc.setLevel(sound * 20);
					}
					long t = p.getDuration();
					p.start();
					if (t != Player.TIME_UNKNOWN) {
						sleep(t / 1000 + 1);
					}
					while (p.getState() == Player.STARTED) {
						sleep(100);
					}
				} catch (Exception e) {
					// Ignored
				}
				p.close();
			}
		}.start();
	}

	void stopMusic() {
		if (midiPlayer != null) {
			midiPlayer.close();
			midiPlayer = null;
		}
	}

	void startMusic(String strMusic) {
		stopMusic();
		if (music == 0) {
			return;
		}
		midiPlayer = createPlayer("/musics/" + strMusic + ".mid", "audio/midi");
		if (midiPlayer == null) {
			return;
		}
		try {
			midiPlayer.setLoopCount(-1);
			midiPlayer.realize();
			setMusicVolume();
			midiPlayer.start();
		} catch (Exception e) {
			// Ignored
		}
	}

	void setMusicVolume() {
		if (midiPlayer != null) {
			VolumeControl vc = (VolumeControl) midiPlayer.getControl("VolumeControl");
			if (vc != null) {
				vc.setLevel(music * 10);
			}
		}
	}
}
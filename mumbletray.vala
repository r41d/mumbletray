using Gtk;
using GLib;

public class Main {
	class AppStatusIcon : Window {
		private StatusIcon trayicon;
		private Gtk.Menu menuSystem;

		public AppStatusIcon() {
			/* Create tray icon */
			trayicon = new Gtk.StatusIcon.from_icon_name("dialog-question");
			trayicon.tooltip_text = "Click to update :)";
			trayicon.visible = true; // visible

			create_menuSystem();
			trayicon.activate.connect(refresh);
			trayicon.popup_menu.connect(rightclickmenu);
			// refresh from time to time
			GLib.Timeout.add_seconds(60, refresh_periodic, GLib.Priority.DEFAULT);
			refresh();
		}

		/* Right button menu */
		public void create_menuSystem() {
			menuSystem = new Gtk.Menu();

			var menuRefresh = new Gtk.ImageMenuItem.with_label("Update");
			menuRefresh.image = new Gtk.Image.from_icon_name(
				"view-refresh", Gtk.IconSize.MENU);
			menuRefresh.activate.connect(refresh);
			menuSystem.append(menuRefresh);

			var menuQuit = new Gtk.ImageMenuItem.with_label("Exit");
			menuQuit.image = new Gtk.Image.from_icon_name(
				"application-exit", Gtk.IconSize.MENU);
			menuQuit.activate.connect(Gtk.main_quit);
			menuSystem.append(menuQuit);

			menuSystem.show_all();
		}

		/* Show popup menu on right button */
		private void rightclickmenu(uint button, uint time) {
			menuSystem.popup(null, null, null, button, time);
		}

		private bool refresh_periodic() {
			refresh();
			return true;
		}

		private void refresh() {
			// this doesn't seem to have a lot of effect :(
			trayicon.icon_name = "view-refresh";
			trayicon.tooltip_text = "Updating...";

			// run mumblecount and mumbleusers
			string countStr = "";
			string users = "";
			string err = "";
			try {
				GLib.Process.spawn_command_line_sync("mumblecount", out countStr, null, null);
				GLib.Process.spawn_command_line_sync("mumbleusers", out users, out err, null);
			} catch (SpawnError e) {
				stdout.printf("SpawnError: %s\n", e.message);
			}
			int count = int.parse(countStr.strip());

			// update icon and tooltip
			if (err.length > 0) {
				trayicon.icon_name = "gtk-dialog-error";
				trayicon.tooltip_text = err.strip();
			} else if (count == 0) {
				trayicon.icon_name = "gtk-close"; // "gtk-no"
				trayicon.tooltip_text = "No one here...";
			} else if (count > 0) {
				trayicon.icon_name = "gtk-apply";
				trayicon.tooltip_text = users.strip() + "\n\nby Mumble Json Tray Tool :)";
			}
		}
	}

	public static int main (string[] args) {
		Gtk.init(ref args);
		var App = new AppStatusIcon();
		App.hide();
		Gtk.main();
		return 0;
	}
}

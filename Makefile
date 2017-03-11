
compile: clean mumblecount mumbleusers mumbletray

all: compile install

mumblecount:
	swipl --stand_alone=true --goal=standalonecount -o mumblecount -c mumblejson.prolog

mumbleusers:
	swipl --stand_alone=true --goal=standaloneusers -o mumbleusers -c mumblejson.prolog

mumbletray:
	valac --pkg=gtk+-2.0 --pkg=glib-2.0 mumbletray.vala

install:
	cp -f mumblecount /usr/local/bin/
	cp -f mumbleusers /usr/local/bin/
	cp -f mumbletray  /usr/local/bin/

clean:
	-rm mumble{count,users,tray}


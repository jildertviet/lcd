(
s.waitForBoot({
~lcd = JLCD.new();
~lcd.setVal(-1, 0);
~songs = List.new();
~paths = [
	"/Users/jildertviet/Desktop/GNP/SC/beeps.scd",
	"/Users/jildertviet/Desktop/GNP/SC/klingelklangels.scd",
	"/Users/jildertviet/Desktop/GNP/SC/klanks.scd",
	"/Users/jildertviet/Desktop/GNP/SC/minimSine.scd",
	"/Users/jildertviet/Desktop/GNP/SC/clickers_v2.scd"
];
~loadFiles = {
	~paths.do{
		|e|
		e.load;
	};
}.value;
~previousTwoSongs = Array.fill(2, {~paths.size.rand});
~currentSongID = 0;
~getRandomNewSong = {
	while({(~currentSongID == ~previousTwoSongs[0]).or(~currentSongID == ~previousTwoSongs[1])},{
			~currentSongID = ~songs.size.rand;
		});
		~previousTwoSongs = ~previousTwoSongs.rotate(1);
		~previousTwoSongs[0] = ~currentSongID;
};
~mainScheduler = Routine.new({
	inf.do{
		|i|
		~getRandomNewSong.value();
		~currentSong = ~songs[~currentSongID];
		("Play song: " ++ ~currentSong).postln;
		{~songName.string = ~currentSong.name;}.fork(AppClock);

		~currentSong.start;
		~currentSong.showGui;

		~currentSong.duration.wait;

		~currentSong.stop;
		~currentSong.hideGui;
		~currentSong.afterWaitTime.wait;
	};
});
~mainWindow = Window.new("LCD", Rect(20, 500, 180, 300));

~button = Button(~mainWindow, Rect(20, 20, 100, 30))
        .states_([
            ["Start", Color.black, Color.green],
            ["Stop", Color.black, Color.red]
        ])
        .action_({ arg butt;
            switch(butt.value,
		1, {
			~mainScheduler.reset();
			~mainScheduler.play();
		},
		0, {
			~mainScheduler.stop();
			~currentSong.stop;
			{~songName.string = "";}.fork(AppClock);
	});
        });
~songName = TextField(w, Rect(20, 60, 100, 30));
~songName.string = "";
~songs.do{
	|e, i|
	var button, guiButton;
	button = Button(~mainWindow, Rect(20, 100+(40*i), 100, 30));
	button.states_([[e.name, Color.black, Color.white], [e.name++" x", Color.black, Color.red]]);
	button.action_({|but| switch(but.value, 1, {e.start; e.showGui}, 0, {e.stop; e.hideGui})});
	guiButton = Button(~mainWindow, Rect(130, 100+(40*i), 30, 30));
	guiButton.states_([["GUI", Color.black, Color.white]]);
	guiButton.action_({e[3].value();});
};
~mainWindow.front;
});
)

/*~songs[4].guiItems
~songs[4][1].value();
~songs[4][2].value();

~currentSong[2].value()
~currentSong[1].value()
~mainScheduler.stop*/
(
~levelsKlanks = Bus.alloc(\control, s, 2).setn(1!2);

SynthDef(\klanks, {
	|gate=1, release=4, freq=#[100, 100, 100, 100], amp=1, trigID=0, triPhase=0, ampBus=1|
	var env = EnvGen.kr(Env.asr(0.01, 1, release), gate, doneAction: 2);
	var noise = BPF.ar(WhiteNoise.ar(0.05), LFPulse.kr(1/10, width: 3/4).range(300, 1000), 0.9);
	var klank;
	var tri = pow(LFTri.kr(1/6, triPhase), SinOsc.kr(1/15).range(10, 1));
	var pulse = LFPulse.kr(6, width: LFPulse.kr([3,4.5]).range(1/4, 3/4) * 0.125);
	var resTime = LFNoise1.kr(1/8).abs * 3.0 + 0.1;
	var sendTrig = SendTrig.kr(pulse[0], trigID, resTime);
	noise = noise * pulse;
	freq = freq*amp;
	klank = DynKlank.ar(
		`[freq, nil, [1, 1, 1, 1]*resTime],
		noise
	);
	Out.ar(0, klank * 0.5 * tri.abs * env * ampBus);
}).add;

~refresh = Routine({
	~synths = (0!4);
	 inf.do{
		|x|
		var freq = [[200, 400, 2000, 1200], [200, 671, 1153, 1523], [200, 671, 1153, 1723]].choose;
		freq.postln;
		~synths.do{|e| e.release};
		~synths.do{
			|e, i|
			~synths[i] = Synth(\klanks, [freq: freq, amp: [0.5,0.25, 1, 0.125].wrapAt(i), trigID: i, triPhase: (1/4)*i*2, ampBus: ~levelsKlanks.subBus(0).asMap]);
		};
		12.do{".".post; 1.wait};
	}
});

~startKlanks = {
	~v.killAll;
	{
		~lcd.setVisualizerMode(1);
		~v.setAlpha(30);
		2.do{
			0.5.wait;
			~lcd.fillRect(-1); // All white
		};
		0.2.wait;
		~lcd.stream();
		~refresh.reset;
		~refresh.play(TempoClock.default);
	}.fork;
	// Register OSC callback
	~index = 0;
	~pulseResponse.free;
	~pulseResponse = OSCFunc({ arg msg, time;
		// [time, msg].postln;
		if(msg[2] == 0, {
			~index = ~index + 1;
			if(~index % 28 < 21, {
				j = JRectangle.new("nonCamFront");
				j.create();
				j.setLoc([[10, 60, 100, 140, 200, 280, 370, 430, 470, 515, 545, 600, 650, 720].reverse.wrapAt(~index) * 1.3 - 20, -100]);
				j.setSize([80, 1000]);
				j.setColor([255, 255, 255, 255]);
				j.addEnv(times: [10, msg[3]*3, msg[3] * 100], kill: true);
			});
		});
	},'/tr', s.addr);
};

~stopKlanks = {
	{
		~refresh.stop;
		0.5.wait;
		~synths.do{|e| e.set(\release, 10); e.release};
		5.wait;
		~pulseResponse.clear;
		~pulseResponse.disable;
		~pulseResponse.free;
		1.wait;
		~lcd.stopStream;
		0.01.wait;
		~lcd.setValLag(-1, 0, 5000);
	}.fork;
};

// {
// SinOsc.ar(Mix.ar(LFPulse.kr([1,2,3,4], 1.0.rand, 1.0.rand).range(100+1000.rand, 1000+4000.rand)), mul: LFPulse.kr([1,2,3,4], 1.0.rand, 1/10)) * LFPulse.kr(1/2, width: 1/4)
// }.play;
{
	var slider;
	~klanksGui = Window.new("klanks", Rect(420, 500, 400, 400));
	slider = EZSlider(~klanksGui,  Rect(20, 20, 400, 30),"klanks",  ControlSpec(0, 4, \amp, 0, 0), 		{|e| ~levelsKlanks.subBus(0).set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz);

	if(~songs != nil, {
		var newSong =
		LCDSong.new(
			"klanks",
			~startKlanks,
			~stopKlanks,
			~klanksGui,
			60*3,
			10,
			[slider]
		);
		newSong.loadSettings();
		~songs.add(newSong);
	});
}.value;
)

// ~startKlanks.value();
// ~stopKlanks.value();
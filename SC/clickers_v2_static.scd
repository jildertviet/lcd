(
~clickersVolumeBus = Bus.alloc(\control, s);
~initLCDsClickers = {
	{
		~lcd.setVal(-1, 0); // All off, because envelopes are being used
		~lcd.setVisualizerMode(0); // LCD's own content
		2.do{
			0.5.wait;
			~lcd.fillRect(-1); 	// All full white
		}
	}.fork;
};

SynthDef(\clicker, {
	|amp=15, dcCo = 0.5, release=100, trigID=0, panning=0, noiseSinFreq= 1500, lowFreqMultiplier = 1, pulseFreq=1, pulsePhase=0, lagTime=0.1, gate=1, fadeTime=2|
	var out, trig, env;
	var noise = PinkNoise.ar(1) + SinOsc.ar(noiseSinFreq);
	var lowFreq = 500 * lowFreqMultiplier+ 5000;
	var pulse = LFPulse.kr(pulseFreq, pulsePhase);
	var bpfFreq = pulse.range(lowFreq, lowFreq*Scale.chromatic.ratios.[5]);
	var bpf = BPF.ar(noise, bpfFreq, 0.1);
	env = EnvGate(1, gate, fadeTime);
	trig = SendTrig.kr(pulse, trigID);
	bpf = HPF.ar(bpf, 500);
	out = bpf * Lag.kr(LeakDC.kr(pulse, dcCo), lagTime);
	out = Pan2.ar(out, panning);
	Out.ar(0, out * amp * env);
}).add;

~startClickers = {
	var num = 4;
	~clickersRelease;
	~initLCDsClickers.value();
	~shuffledClickers = 0;
	~clickerGroups = Array.newClear(4);
	~random = (0..24).scramble;
	~clickerGroups[1] = ~random.at((0..3));
	~clickerGroups[2] = ~random.at((4..5));
	~clickerGroups[3] = ~random.at((6..13));
	~clicking = {
		1.wait;
		inf.do{
			var dcCo = [0.5, 0.8 + 0.09.rand].choose;
			~clickersRelease = dcCo * 200;
			~shuffledClickers = Array.fill(3, {15.rand});
			~synthsClickers.do{|e| if(e!= nil, {e.free})};
			~synthsClickers = Array.newClear(num);
			num.do{
				|i|
				~synthsClickers[i] = Synth.new(\clicker, [
					dcCo: dcCo,
					release: ~clickersRelease,
					trigID: i,
					panning: 2.0.rand-1,
					noiseSinFreq: [1500,3000].choose,
					lowFreqMultiplier: (1..10).choose,
					pulseFreq: (1..3).choose * [0.5,1].choose,
					pulsePhase: (1..4).choose/4,
					lagTime: [0.05,0.01].choose
				]);
				~synthsClickers[i].map(\amp, ~clickersVolumeBus);
			};
			([4, 8, 8, 16].choose).wait;
		};
	}.fork;
	if(~clickersBass != nil, {~clickersBass.free});
	{
		1.wait;
		~clickersBass = {
			|amp=1, gate=1, fadeTime=2|
			var env = EnvGate(1, gate, fadeTime);
			SinOsc.ar([60,61], mul: LFPulse.kr(1/4, width: 1/6).range(0.02, 0.2)) * amp * env
		}.play;
	}.fork;

	~clickersIndex = 0;
	~clickersOSC.free;
	~clickersOSC = OSCFunc({ arg msg, time;
		// [time, msg].postln;
		switch(msg[2],
			0, {
				~lcd.doEnv(~shuffledClickers.wrapAt(~clickersIndex), 255, [1, 10, ~clickersRelease]);
			},
			1, {
				~lcd.doEnv(~clickerGroups[1].wrapAt(~clickersIndex), 255, [1, 50, ~clickersRelease]);
				~lcd.doEnv(~clickerGroups[1].wrapAt(~clickersIndex+2), 255, [1, 50, ~clickersRelease]);
			},
			2,{
				~lcd.doEnv(~clickerGroups[2], 255, [1, 10, ~clickersRelease]);
			},
			3, {
				~clickersIndex = ~clickersIndex + 1;
				~lcd.doEnv(~clickerGroups[3].wrapAt(~clickersIndex), 255, [1, 50, ~clickersRelease]);
				~lcd.doEnv(~clickerGroups[3].wrapAt(~clickersIndex+4), 255, [1, 50, ~clickersRelease]);
		});
	},'/tr', s.addr);
};
~stopClickers = {
	~clickersBass.release;
	~clickersBass = nil;
	~clickersOSC.disable;
	~clickersOSC.clear;
	~clickersOSC.free;
	~clicking.stop;
	~synthsClickers.do{|e| e.release};
	~synthsClickers = nil;
};
~clickersGuiWindow = Window.new("Clickers", Rect(420, 500, 400, 400));
{
	// Mix
	var sinAmp, clickersAmp;
	sinAmp = EZSlider(~clickersGuiWindow,  Rect(20, 20, 400, 30),"sine amp",  ControlSpec(0, 4, \amp, 0, 0), {|e| ~clickersBass.set(\amp, e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz);
	clickersAmp = EZSlider(~clickersGuiWindow, Rect(20, 60, 400, 30),"clickers amp",  ControlSpec(0, 35, \amp, 0, 0), {|e| ~clickersVolumeBus.set(e.value)}, 1, unitWidth:30, numberWidth:60,layout:\horz);

	if(~songs != nil, {
		var newSong = LCDSong.new(
			"clickers",
			~startClickers,
			~stopClickers,
			~clickersGuiWindow,
			60*3,
			0,
			[sinAmp, clickersAmp]
		);
		newSong.loadSettings(); // Sets values to sinAmp and clickersAmp
		~songs.add(newSong);
	});
}.value;
)

// ~startClickers.value
// ~stopClickers.value
// ~clickersVolumeBus.set(0)
